import base64
import json
import os
import subprocess
import threading
import queue
import time
from typing import Optional, Dict, Any

from voice.asr_interface import ASREngine, ASRResult


def _decode_audio_tts(response: dict) -> Optional[bytes]:
    """
    Decode TTS audio from IPC response.
    Accepts both 'audio_base64' (new field) and 'audio_tts' (legacy field).
    Returns raw WAV bytes, or None if absent/invalid.
    """
    # Prefer new canonical field, fall back to legacy
    b64_str = response.get("audio_base64") or response.get("audio_tts")
    if not b64_str:
        return None
    try:
        return base64.b64decode(b64_str)
    except Exception:
        return None


class WSLIndicConformerASR(ASREngine):
    """
    Windows client for the persistent WSL pipeline worker.
    Communicates via stdin/stdout IPC over JSON protocols.

    The WSL worker runs:
      IndicConformer ASR  (NeMo, CUDA)
      IndicTrans2         (translation)
      Indic Parler-TTS    (WAV synthesis)

    This Windows client receives the resulting WAV bytes and stores them
    in self.last_audio for playback via AudioOutput.

    PALASH_OUTPUT_DEVICE env var selects the sounddevice output device.
    """

    def __init__(
        self,
        wsl_script: str,
        wsl_python: str,
        sample_rate: int = 16000,
        distro: Optional[str] = None,
        source_language: str = "hin_Deva",
        target_language: str = "sat_Olck",
    ):
        self.wsl_script = wsl_script
        self.wsl_python = wsl_python
        self.sample_rate = sample_rate
        self.distro = distro
        self.source_language = source_language
        self.target_language = target_language

        self.process = None
        self.response_queue = queue.Queue()
        self.reader_thread = None
        self.stderr_thread = None
        self.running = False

        self.audio_buffer = bytearray()

        # Last WAV bytes received from WSL TTS (already decoded from base64)
        self.last_audio: Optional[bytes] = None

        self.last_result_metadata: Dict[str, Any] = {
            "recognized_text": "",
            "translated_text": "",
            "translation_source": None,
            "asr_latency_ms": 0,
            "translation_latency_ms": 0,
            "tts_latency_ms": 0,
            "tts_success": False,
            "audio_format": None,
            "audio_tts": None,
            "success": False,
            "error": None,
        }

    def get_last_audio(self) -> Optional[bytes]:
        """Return the most recent WAV bytes received from WSL TTS."""
        return self.last_audio

    def supports_language(self, language_code: str) -> bool:
        """Checks if ASR recognition is supported for language_code."""
        norm = language_code.lower()
        return norm in ("hi", "hin_deva", "hindi")

    def set_direction(self, source_language: str, target_language: str):
        """Set translation direction (e.g. hin_Deva -> sat_Olck)."""
        self.source_language = source_language
        self.target_language = target_language

    def _build_command(self):
        if self.distro:
            return ["wsl.exe", "-d", self.distro, self.wsl_python, self.wsl_script]
        return ["wsl.exe", self.wsl_python, self.wsl_script]

    def _reader_loop(self):
        """Read JSON IPC messages from worker stdout. One JSON object per line."""
        try:
            for line in self.process.stdout:
                line = line.strip()
                if not line:
                    continue
                try:
                    response = json.loads(line)
                    self.response_queue.put(response)
                except (json.JSONDecodeError, ValueError):
                    print(f"[WSL ASR Client] Non-JSON line from stdout: {line!r}")
        except (OSError, UnicodeDecodeError) as e:
            if self.running:
                print(f"[WSL ASR Client] stdout reader error: {type(e).__name__}: {e}")

    def _stderr_loop(self):
        """Forward worker stderr lines to the Windows terminal. Never parse as JSON."""
        try:
            for line in self.process.stderr:
                line = line.rstrip()
                if line:
                    print(f"[WSL Worker] {line}", flush=True)
        except (OSError, UnicodeDecodeError):
            pass

    def _start_worker(self):
        if self.process is not None and self.process.poll() is None:
            return

        command = self._build_command()
        print("[WSL ASR Client] Starting worker process...")
        print("Command:", " ".join(command))

        self.process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,   # IPC pipe — JSON messages only
            stderr=subprocess.PIPE,   # captured separately → forwarded to terminal
            text=True,
            encoding="utf-8",
            errors="replace",
            bufsize=1,
        )

        self.running = True

        self.reader_thread = threading.Thread(
            target=self._reader_loop,
            daemon=True,
            name="WSL-ASR-Reader",
        )
        self.reader_thread.start()

        self.stderr_thread = threading.Thread(
            target=self._stderr_loop,
            daemon=True,
            name="WSL-ASR-Stderr",
        )
        self.stderr_thread.start()

        print("[WSL ASR Client] Waiting for worker readiness (model load ~60-300 s)...")
        deadline = time.perf_counter() + 300

        while time.perf_counter() < deadline:
            try:
                response = self.response_queue.get(timeout=0.5)
            except queue.Empty:
                if self.process.poll() is not None:
                    raise RuntimeError("WSL worker process terminated prematurely.")
                continue

            if response.get("type") == "ready":
                print("[WSL ASR Client] Worker ready.")
                print(f"[WSL ASR Client] Device: {response.get('device')}")
                print(f"[WSL ASR Client] TTS Available: {response.get('tts_available')}")
                return

        raise TimeoutError("Timed out waiting for WSL worker process.")

    def start_stream(self):
        self._start_worker()
        self.audio_buffer.clear()
        self.last_audio = None
        self.last_result_metadata = {
            "recognized_text": "",
            "translated_text": "",
            "translation_source": None,
            "asr_latency_ms": 0,
            "translation_latency_ms": 0,
            "tts_latency_ms": 0,
            "tts_success": False,
            "audio_format": None,
            "audio_tts": None,
            "success": False,
            "error": None,
        }

    def accept_audio(self, audio_chunk: bytes) -> bool:
        if not audio_chunk:
            return False
        self.audio_buffer.extend(audio_chunk)
        return False

    def get_partial_result(self) -> ASRResult:
        return ASRResult("", False)

    def _parse_result_response(self, response: dict):
        """Extract and store all fields from a pipeline result response."""
        wav_bytes = _decode_audio_tts(response)
        self.last_audio = wav_bytes

        self.last_result_metadata = {
            "recognized_text": response.get("recognized_text", ""),
            "translated_text": response.get("translated_text", ""),
            "translation_source": response.get("translation_source"),
            "asr_latency_ms": response.get("asr_latency_ms", 0),
            "translation_latency_ms": response.get("translation_latency_ms", 0),
            "tts_latency_ms": response.get("tts_latency_ms", 0),
            "tts_success": response.get("tts_success", wav_bytes is not None),
            "audio_format": response.get("audio_format"),
            # Store decoded bytes (not base64) for direct use by AudioOutput
            "audio_tts": wav_bytes,
            "success": response.get("success", False),
            "error": response.get("error"),
        }

    def get_final_result(self, enable_tts: bool = True) -> ASRResult:
        """
        Send accumulated audio to WSL worker and await full pipeline results.
        Returns ASRResult with the recognized Hindi text.
        Decoded WAV bytes are stored in self.last_audio and self.last_result_metadata["audio_tts"].
        """
        if not self.audio_buffer:
            return ASRResult("", True)

        if self.process is None or self.process.poll() is not None:
            self._start_worker()

        audio_bytes = bytes(self.audio_buffer)
        self.audio_buffer.clear()
        audio_b64 = base64.b64encode(audio_bytes).decode("ascii")

        request = {
            "type": "transcribe",
            "source_language": self.source_language,
            "target_language": self.target_language,
            "enable_tts": enable_tts,
            "audio": audio_b64,
        }

        request_json = json.dumps(request, ensure_ascii=False) + "\n"
        self.process.stdin.write(request_json)
        self.process.stdin.flush()

        deadline = time.perf_counter() + 180

        while time.perf_counter() < deadline:
            try:
                response = self.response_queue.get(timeout=0.5)
            except queue.Empty:
                if self.process.poll() is not None:
                    raise RuntimeError("WSL worker process stopped unexpectedly.")
                continue

            if response.get("type") != "result":
                continue

            self._parse_result_response(response)
            recognized_text = response.get("recognized_text", "").strip()
            return ASRResult(recognized_text, True)

        raise TimeoutError("Timed out waiting for WSL pipeline result.")

    def synthesize(self, text: str, language: str = "sat_Olck") -> Optional[bytes]:
        """
        Request direct TTS synthesis from the WSL worker for given text.
        Returns decoded WAV bytes, or None on failure.
        Does NOT import or use parler_tts on the Windows side.
        """
        if not text or not text.strip():
            return None

        if self.process is None or self.process.poll() is not None:
            self._start_worker()

        request = {
            "type": "synthesize",
            "text": text,
            "language": language,
        }

        request_json = json.dumps(request, ensure_ascii=False) + "\n"
        self.process.stdin.write(request_json)
        self.process.stdin.flush()

        deadline = time.perf_counter() + 180

        while time.perf_counter() < deadline:
            try:
                response = self.response_queue.get(timeout=0.5)
            except queue.Empty:
                if self.process.poll() is not None:
                    raise RuntimeError("WSL worker process stopped unexpectedly.")
                continue

            if response.get("type") != "result":
                continue

            self._parse_result_response(response)
            return self.last_audio   # None if TTS failed, WAV bytes if success

        raise TimeoutError("Timed out waiting for WSL TTS synthesis result.")

    # ------------------------------------------------------------------
    # Backwards-compat property alias
    # ------------------------------------------------------------------

    @property
    def last_translation(self) -> Dict[str, Any]:
        return self.last_result_metadata

    def stop_stream(self):
        self.audio_buffer.clear()

    def close(self):
        self.running = False
        if self.process is None or self.process.poll() is not None:
            return

        try:
            shutdown_request = json.dumps({"type": "shutdown"}, ensure_ascii=False) + "\n"
            self.process.stdin.write(shutdown_request)
            self.process.stdin.flush()
        except Exception:
            pass

        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.process.kill()
            self.process.wait()

        self.process = None
        print("[WSL ASR Client] Worker stopped.")
