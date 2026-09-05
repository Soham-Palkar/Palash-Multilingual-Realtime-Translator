import sys
import os
import time
import threading
import queue
from typing import Optional, Dict, Any

# Allow imports from AI POC/
sys.path.append(
    os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..")
    )
)

from voice.microphone import Microphone
from voice.audio_buffer import AudioBuffer
from voice.vad import VoiceActivityDetector, VADState
from voice.asr_interface import ASREngine
from voice.wsl_asr_client import WSLIndicConformerASR
from voice.tts_interface import TTSEngine, DummyTTSBackend
from voice.audio_output import AudioOutput
try:
    from translation.translator import Translator
except ImportError:
    Translator = None


class VoicePipeline:
    """
    Offline Bidirectional Classroom Voice Translation Pipeline.

    Flow:
        Physical Microphone (Windows Host)
             ↓
        VAD (Energy-based speech segmentation)
             ↓
        ASR (IndicConformer in WSL / CUDA)
             ↓
        Translation (IndicTrans2 hin_Deva ↔ sat_Olck)
             ↓
        TTS (Indic Parler-TTS speech synthesis)
             ↓
        Speaker (AudioOutput PyAudio on Windows Host)

    High-Resolution Latency Tracking & Non-blocking Capture Architecture.
    """

    def __init__(
        self,
        source_language: str = "hin_Deva",
        target_language: str = "sat_Olck",
        asr_engine: Optional[ASREngine] = None,
        tts_engine: Optional[TTSEngine] = None,
        translator: Optional[Translator] = None,
        audio_output: Optional[AudioOutput] = None,
        phrase_bank_path: Optional[str] = None,
        energy_threshold: int = 800,
        sample_rate: int = 16000,
        wsl_script: Optional[str] = None,
        wsl_python: Optional[str] = None,
    ):
        self.source_language = source_language
        self.target_language = target_language
        self.sample_rate = sample_rate

        # --------------------------------------------------
        # Components
        # --------------------------------------------------
        self.microphone = Microphone(
            rate=sample_rate,
            channels=1,
            chunk_size=1024
        )

        self.audio_buffer = AudioBuffer(
            sample_rate=sample_rate
        )

        self.vad = VoiceActivityDetector(
            energy_threshold=energy_threshold,
            sample_rate=sample_rate
        )

        # Default ASR: Use persistent WSL worker client if parameters provided
        if asr_engine:
            self.asr = asr_engine
        elif wsl_script and wsl_python:
            self.asr = WSLIndicConformerASR(
                wsl_script=wsl_script,
                wsl_python=wsl_python,
                sample_rate=sample_rate,
                source_language=source_language,
                target_language=target_language
            )
        else:
            raise RuntimeError(
                "No ASR engine provided. Pass asr_engine= or wsl_script=/wsl_python=."
            )

        self.tts = tts_engine or DummyTTSBackend()
        if translator:
            self.translator = translator
        elif Translator is not None:
            self.translator = Translator(phrase_bank_path=phrase_bank_path)
        else:
            self.translator = None

        self.audio_output = audio_output or AudioOutput(sample_rate=sample_rate)

        # --------------------------------------------------
        # State & Queues
        # --------------------------------------------------
        self.running = False
        self._capture_thread = None
        self._audio_queue = queue.Queue(maxsize=100) # Bounded queue to avoid memory leak
        self.utterance_counter = 0

        # High-resolution Latency Breakdown
        self.last_latency: Dict[str, Any] = {
            "utterance_id": 0,
            "speech_duration_s": 0.0,
            "asr_ms": 0.0,
            "translation_ms": 0.0,
            "tts_ms": 0.0,
            "audio_prepare_ms": 0.0,
            "speech_end_to_playback_start_ms": 0.0,
            "total_pipeline_ms": 0.0,
        }

    def set_direction(
        self,
        source_language: str,
        target_language: str,
    ):
        """
        Set or switch translation direction. Defensive capability check for Santali ASR.
        """
        if hasattr(self.asr, "supports_language"):
            if not self.asr.supports_language(source_language):
                err_msg = (
                    f"Cannot set direction {source_language} -> {target_language}: "
                    f"Santali ASR pending model integration."
                )
                print(f"[Pipeline ERROR] {err_msg}")
                raise NotImplementedError(err_msg)

        self.source_language = source_language
        self.target_language = target_language

        if hasattr(self.asr, "set_direction"):
            self.asr.set_direction(source_language, target_language)

        print(f"[Pipeline] Direction set: {source_language} -> {target_language}")

    def _capture_loop(self):
        """Background loop reading physical microphone audio into bounded queue."""
        while self.running:
            try:
                chunk = self.microphone.read_chunk()
                if chunk:
                    try:
                        self._audio_queue.put(chunk, block=False)
                    except queue.Full:
                        pass # Drop oldest or ignore overflow cleanly
            except Exception as e:
                if self.running:
                    print(f"[Microphone ERROR] Capture error: {e}")
                break

    def process_utterance(self, speech_audio: bytes, speech_start_perf: float, speech_end_perf: float):
        """
        Process a complete utterance detected by VAD through ASR, Translation, TTS, and Speaker output.
        Accurately records high-resolution timing using time.perf_counter().
        """
        if not speech_audio:
            return

        self.utterance_counter += 1
        utt_id = self.utterance_counter
        speech_dur_s = round(speech_end_perf - speech_start_perf, 3)

        print(f"\n[Pipeline Utterance #{utt_id}] Speech duration: {speech_dur_s} s | Processing pipeline...")

        # 1. ASR, Translation, TTS Execution via WSL IPC Worker
        ipc_start = time.perf_counter()
        
        if isinstance(self.asr, WSLIndicConformerASR):
            self.asr.start_stream()
            self.asr.accept_audio(speech_audio)
            asr_res = self.asr.get_final_result(enable_tts=True)
            ipc_end = time.perf_counter()
            ipc_total_ms = round((ipc_end - ipc_start) * 1000, 2)

            recognized_text = asr_res.text.strip()
            wsl_meta = self.asr.last_result_metadata

            if not recognized_text:
                print(f"[ASR #{utt_id}] No speech recognized.")
                return

            asr_ms = round(wsl_meta.get("asr_latency_ms", 0.0), 2)
            print(f"[ASR #{utt_id}] Recognized ({asr_ms} ms): '{recognized_text}'")

            translated_text = wsl_meta.get("translated_text", "")
            trans_source = wsl_meta.get("translation_source", "indictrans2")
            trans_ms = round(wsl_meta.get("translation_latency_ms", 0.0), 2)
            print(f"[Translation #{utt_id}] Target: '{translated_text}' ({trans_source}, {trans_ms} ms)")

            tts_audio = wsl_meta.get("audio_tts")
            tts_ms = round(wsl_meta.get("tts_latency_ms", 0.0), 2)
            ipc_overhead_ms = max(0.0, round(ipc_total_ms - (asr_ms + trans_ms + tts_ms), 2))
            if tts_audio:
                print(f"[TTS #{utt_id}] Synthesized {len(tts_audio)} WAV bytes "
                      f"({tts_ms} ms | IPC Overhead: {ipc_overhead_ms} ms)")
            else:
                tts_err = wsl_meta.get("error") or "(no error reported)"
                print(f"[TTS #{utt_id}] NO AUDIO — tts_success={wsl_meta.get('tts_success')} "
                      f"translated='{translated_text[:40]}' error={tts_err}")
        else:
            # Standalone fallback engine pipeline
            self.asr.start_stream()
            self.asr.accept_audio(speech_audio)
            asr_res = self.asr.get_final_result()
            asr_end = time.perf_counter()
            asr_ms = round((asr_end - ipc_start) * 1000, 2)
            ipc_overhead_ms = 0.0

            recognized_text = asr_res.text.strip()
            if not recognized_text:
                print(f"[ASR #{utt_id}] No speech recognized.")
                return

            print(f"[ASR #{utt_id}] Recognized ({asr_ms} ms): '{recognized_text}'")

            # Translation
            trans_start = time.perf_counter()
            trans_res = self.translator.translate(
                recognized_text, self.source_language, self.target_language
            )
            trans_end = time.perf_counter()
            trans_ms = round((trans_end - trans_start) * 1000, 2)

            if not trans_res["success"]:
                print(f"[Translation ERROR #{utt_id}] {trans_res.get('error')}")
                return

            translated_text = trans_res["translated_text"]
            print(f"[Translation #{utt_id}] '{translated_text}' ({trans_res['translation_source']}, {trans_ms} ms)")

            # TTS
            tts_start = time.perf_counter()
            tts_audio = self.tts.synthesize(translated_text, self.target_language)
            tts_end = time.perf_counter()
            tts_ms = round((tts_end - tts_start) * 1000, 2)

        # Audio Preparation & Speaker Playback
        playback_start_perf = time.perf_counter()
        speech_end_to_playback_start_ms = round((playback_start_perf - speech_end_perf) * 1000, 2)
        speech_end_to_playback_start_s = speech_end_to_playback_start_ms / 1000.0

        if tts_audio:
            # sample_rate omitted — AudioOutput reads it from the WAV RIFF header
            play_res = self.audio_output.play(tts_audio)
            if play_res.get("success"):
                print(
                    f"[Speaker #{utt_id}] Playback complete | "
                    f"device={play_res.get('device')} | "
                    f"rate={play_res.get('sample_rate')} Hz | "
                    f"duration={play_res.get('duration_ms')} ms | "
                    f"rms={play_res.get('rms', 0):.4f} | "
                    f"peak={play_res.get('peak', 0):.4f} | "
                    f"time-to-playback={speech_end_to_playback_start_s:.3f} s"
                )
            else:
                print(f"[Speaker #{utt_id}] Playback FAILED: {play_res.get('error')}")
        else:
            print(f"[TTS #{utt_id}] No audio generated for playback.")

        total_pipeline_ms = round((time.perf_counter() - speech_start_perf) * 1000, 2)

        # Update Metrics Structure
        self.last_latency = {
            "utterance_id": utt_id,
            "speech_duration_s": speech_dur_s,
            "asr_ms": asr_ms,
            "translation_ms": trans_ms,
            "tts_ms": tts_ms,
            "ipc_overhead_ms": ipc_overhead_ms,
            "speech_end_to_playback_start_ms": speech_end_to_playback_start_ms,
            "total_pipeline_ms": total_pipeline_ms,
        }

        print("\n" + "=" * 60)
        print(f"[PERFORMANCE REPORT — UTTERANCE #{utt_id}]")
        print(f"  Speech Duration:               {speech_dur_s} s")
        print(f"  ASR Inference:                 {asr_ms} ms")
        print(f"  Translation Inference:         {trans_ms} ms")
        print(f"  TTS Synthesis:                 {tts_ms} ms")
        print(f"  IPC / Buffer Overhead:         {ipc_overhead_ms} ms")
        print(f"  Speech-End -> Playback Start:  {speech_end_to_playback_start_s:.3f} s  (Target <= 4-5s)")
        print(f"  Total Pipeline Duration:       {total_pipeline_ms} ms")
        print("=" * 60 + "\n")

    def start(self):
        """Start the real-time voice translation pipeline."""
        print("=" * 70)
        print("PALASH VOICE TRANSLATION PIPELINE STARTING")
        print(f"Direction: {self.source_language} -> {self.target_language}")
        print("=" * 70)

        # Check direction capability before opening mic
        try:
            self.set_direction(self.source_language, self.target_language)
        except NotImplementedError as nie:
            print(f"[Pipeline ABORTED] {nie}")
            return

        self.microphone.select_audio_input()
        self.microphone.start()

        if hasattr(self.asr, "start_stream"):
            self.asr.start_stream()

        self.running = True
        self._capture_thread = threading.Thread(
            target=self._capture_loop,
            daemon=True,
            name="MicCaptureThread"
        )
        self._capture_thread.start()

        print("[PIPELINE] Ready. Listening on physical microphone...")

        speech_audio = bytearray()
        speech_start_perf = None

        try:
            while self.running:
                try:
                    chunk = self._audio_queue.get(timeout=0.05)
                except queue.Empty:
                    continue

                state = self.vad.process(chunk)

                if state in (VADState.SPEECH_DETECTED, VADState.RECORDING):
                    if speech_start_perf is None:
                        speech_start_perf = time.perf_counter()
                    speech_audio.extend(chunk)

                elif state == VADState.END_OF_SPEECH and len(speech_audio) > 0:
                    speech_end_perf = time.perf_counter()
                    utterance_data = bytes(speech_audio)
                    start_perf = speech_start_perf or speech_end_perf

                    speech_audio.clear()
                    speech_start_perf = None
                    self.vad.reset()

                    # Process utterance
                    self.process_utterance(utterance_data, start_perf, speech_end_perf)
                    print("Listening on physical microphone...")

        except KeyboardInterrupt:
            print("\n[Pipeline] Stopped by user (Ctrl+C).")
        except Exception as e:
            print(f"\n[Pipeline ERROR] {type(e).__name__}: {e}")
        finally:
            self.stop()

    def stop(self):
        """Stop pipeline and release physical resources."""
        self.running = False
        if self._capture_thread:
            self._capture_thread.join(timeout=2)
            self._capture_thread = None

        try:
            self.microphone.stop()
            self.microphone.close()
        except Exception:
            pass

        try:
            self.audio_output.close()
        except Exception:
            pass

        if hasattr(self.asr, "close"):
            try:
                self.asr.close()
            except Exception:
                pass

        print("[Pipeline] Stopped.")