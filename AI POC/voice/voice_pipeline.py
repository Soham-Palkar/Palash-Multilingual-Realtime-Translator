import sys
import os
import time
import threading
import queue

import pyaudio

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
from voice.indicconformer_asr import IndicConformerASRBackend
from voice.tts_interface import TTSEngine, DummyTTSBackend
from translation.translator import Translator


class VoicePipeline:
    """
    Real-time voice translation pipeline.

    Flow:
        Microphone
            ↓
        VAD
            ↓
        ASR
            ↓
        Translation
            ↓
        TTS
            ↓
        Speaker

    The microphone runs on a dedicated background thread so
    audio capture is separated from ASR/translation/TTS processing.
    """

    def __init__(
        self,
        source_language: str = "hin_Deva",
        target_language: str = "sat_Olck",
        asr_engine: ASREngine = None,
        tts_engine: TTSEngine = None,
        translator: Translator = None,
        phrase_bank_path: str = None,
        energy_threshold: int = 500,
        sample_rate: int = 16000,
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
            energy_threshold=energy_threshold
        )

        # Use real IndicConformer ASR by default.
        # A different ASR backend can still be injected.
        self.asr = asr_engine or IndicConformerASRBackend(
            language_id=self._get_asr_language_id(source_language),
            sample_rate=sample_rate,
            decoder="ctc",
        )

        # TTS will be replaced with a real offline backend later.
        self.tts = tts_engine or DummyTTSBackend()

        # Use existing translation engine.
        self.translator = translator or Translator(
            phrase_bank_path=phrase_bank_path
        )

        # --------------------------------------------------
        # State
        # --------------------------------------------------

        self.running = False
        self._capture_thread = None
        self._audio_queue = queue.Queue()

        # --------------------------------------------------
        # Latency tracking
        # --------------------------------------------------

        self.last_latency = {
            "vad_ms": 0,
            "asr_ms": 0,
            "translation_ms": 0,
            "tts_ms": 0,
            "total_end_to_end_ms": 0,
        }

    # ======================================================
    # Language handling
    # ======================================================

    def _get_asr_language_id(self, language_code: str) -> str:
        """
        Convert PALASH language codes to IndicConformer
        language IDs.
        """

        mapping = {
            "hin_Deva": "hi",
            "sat_Olck": "sat",
        }

        if language_code not in mapping:
            raise ValueError(
                f"Unsupported ASR language: {language_code}"
            )

        return mapping[language_code]

    # ======================================================
    # Direction
    # ======================================================

    def set_direction(self, source: str, target: str):
        """
        Change translation direction.

        Example:
            hin_Deva -> sat_Olck
            sat_Olck -> hin_Deva

        NOTE:
        The ASR backend is not recreated here yet.
        Bidirectional ASR model switching will be added
        when Santali ASR is integrated.
        """

        self.source_language = source
        self.target_language = target

        print(
            f"Direction set: "
            f"{source} -> {target}"
        )

    # ======================================================
    # Microphone capture
    # ======================================================

    def _capture_loop(self):
        """
        Continuously read microphone audio in a background
        thread and put chunks into the processing queue.
        """

        while self.running:

            try:
                chunk = self.microphone.read_chunk()

                if chunk:
                    self._audio_queue.put(chunk)

            except Exception as e:

                if self.running:
                    print(
                        f"[Microphone] Capture error: {e}"
                    )

                break

    # ======================================================
    # Start pipeline
    # ======================================================

    def start(self):
        """
        Start the real-time voice pipeline.
        """

        print("=" * 60)
        print("PALASH Voice Pipeline — Starting")
        print(
            f"Direction: "
            f"{self.source_language} -> "
            f"{self.target_language}"
        )
        print("=" * 60)

        try:

            # --------------------------------------------------
            # Microphone
            # --------------------------------------------------

            self.microphone.select_audio_input()
            self.microphone.start()

            # --------------------------------------------------
            # ASR
            # --------------------------------------------------

            self.asr.start_stream()

            # --------------------------------------------------
            # Start capture
            # --------------------------------------------------

            self.running = True

            self._capture_thread = threading.Thread(
                target=self._capture_loop,
                daemon=True
            )

            self._capture_thread.start()

            speech_audio = bytearray()
            utterance_start = None

            # --------------------------------------------------
            # Main processing loop
            # --------------------------------------------------

            while self.running:

                try:
                    chunk = self._audio_queue.get(
                        timeout=0.1
                    )

                except queue.Empty:
                    continue

                # ==================================================
                # VAD
                # ==================================================

                t_vad = time.time()

                state = self.vad.process(chunk)

                vad_ms = (
                    time.time() - t_vad
                ) * 1000

                # ==================================================
                # Speech detected / recording
                # ==================================================

                if state in (
                    VADState.SPEECH_DETECTED,
                    VADState.RECORDING,
                ):

                    if utterance_start is None:
                        utterance_start = time.time()

                    speech_audio.extend(chunk)

                    # Feed audio to ASR backend.
                    self.asr.accept_audio(chunk)

                # ==================================================
                # End of speech
                # ==================================================

                elif (
                    state == VADState.END_OF_SPEECH
                    and len(speech_audio) > 0
                ):

                    print(
                        "\n[VAD] Speech ended. Processing..."
                    )

                    # --------------------------------------------------
                    # ASR
                    # --------------------------------------------------

                    t_asr = time.time()

                    asr_result = (
                        self.asr.get_final_result()
                    )

                    asr_ms = (
                        time.time() - t_asr
                    ) * 1000

                    recognized_text = (
                        asr_result.text.strip()
                    )

                    if not recognized_text:

                        print(
                            "[ASR] Empty result, skipping."
                        )

                        speech_audio.clear()
                        utterance_start = None

                        self.asr.start_stream()

                        continue

                    print(
                        f"[ASR] Recognized: "
                        f"{recognized_text}"
                    )

                    # --------------------------------------------------
                    # Translation
                    # --------------------------------------------------

                    t_trans = time.time()

                    translation_result = (
                        self.translator.translate(
                            recognized_text,
                            self.source_language,
                            self.target_language,
                        )
                    )

                    translation_ms = (
                        time.time() - t_trans
                    ) * 1000

                    if translation_result["success"]:

                        translated_text = (
                            translation_result[
                                "translated_text"
                            ]
                        )

                        print(
                            f"[Translation] "
                            f"{translated_text} "
                            f"("
                            f"{translation_result['translation_source']}, "
                            f"{translation_ms:.0f}ms"
                            f")"
                        )

                    else:

                        print(
                            "[Translation] FAILED: "
                            f"{translation_result['error']}"
                        )

                        speech_audio.clear()
                        utterance_start = None

                        self.asr.start_stream()

                        continue

                    # --------------------------------------------------
                    # TTS
                    # --------------------------------------------------

                    t_tts = time.time()

                    tts_audio = self.tts.synthesize(
                        translated_text,
                        self.target_language
                    )

                    tts_ms = (
                        time.time() - t_tts
                    ) * 1000

                    # --------------------------------------------------
                    # Playback
                    # --------------------------------------------------

                    if tts_audio:
                        self._play_audio(tts_audio)

                    # --------------------------------------------------
                    # Latency
                    # --------------------------------------------------

                    total_ms = (
                        (
                            time.time()
                            - utterance_start
                        ) * 1000
                        if utterance_start
                        else 0
                    )

                    self.last_latency = {
                        "vad_ms": round(
                            vad_ms, 2
                        ),
                        "asr_ms": round(
                            asr_ms, 2
                        ),
                        "translation_ms": round(
                            translation_ms, 2
                        ),
                        "tts_ms": round(
                            tts_ms, 2
                        ),
                        "total_end_to_end_ms": round(
                            total_ms, 2
                        ),
                    }

                    print(
                        f"[Latency] "
                        f"{self.last_latency}"
                    )

                    # --------------------------------------------------
                    # Reset for next utterance
                    # --------------------------------------------------

                    speech_audio.clear()
                    utterance_start = None

                    self.asr.start_stream()

        except KeyboardInterrupt:

            print(
                "\n[Pipeline] Interrupted by user."
            )

        except Exception as e:

            print(
                f"\n[Pipeline] Error: {e}"
            )

        finally:

            self.stop()

    # ======================================================
    # Speaker
    # ======================================================

    def _play_audio(self, pcm_data: bytes):
        """
        Play PCM16 mono audio through system speaker.
        """

        try:

            p = pyaudio.PyAudio()

            stream = p.open(
                format=pyaudio.paInt16,
                channels=1,
                rate=self.sample_rate,
                output=True,
            )

            stream.write(pcm_data)

            stream.stop_stream()
            stream.close()

            p.terminate()

        except Exception as e:

            print(
                f"[Speaker] Playback error: {e}"
            )

    # ======================================================
    # Stop
    # ======================================================

    def stop(self):
        """
        Stop pipeline and release resources.
        """

        self.running = False

        if self._capture_thread:

            self._capture_thread.join(
                timeout=2
            )

            self._capture_thread = None

        try:
            self.asr.stop_stream()
        except Exception:
            pass

        try:
            self.microphone.stop()
        except Exception:
            pass

        print(
            "[Pipeline] Stopped."
        )


# ==========================================================
# CLI
# ==========================================================

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser(
        description=(
            "PALASH Real-Time Voice Translation Pipeline"
        )
    )

    parser.add_argument(
        "--source",
        default="hin_Deva",
        help="Source language code"
    )

    parser.add_argument(
        "--target",
        default="sat_Olck",
        help="Target language code"
    )

    parser.add_argument(
        "--energy",
        type=int,
        default=500,
        help="VAD energy threshold"
    )

    parser.add_argument(
        "--phrase-bank",
        default=None,
        help="Path to verified phrase bank JSON"
    )

    args = parser.parse_args()

    pipeline = VoicePipeline(
        source_language=args.source,
        target_language=args.target,
        energy_threshold=args.energy,
        phrase_bank_path=args.phrase_bank,
    )

    pipeline.start()