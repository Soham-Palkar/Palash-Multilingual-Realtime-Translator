import base64
import json
import subprocess
import threading
import queue
import time

from voice.asr_interface import ASREngine, ASRResult


class WSLIndicConformerASR(ASREngine):

    def __init__(
        self,
        wsl_script: str,
        wsl_python: str,
        sample_rate: int = 16000,
        distro: str = None,
    ):
        self.wsl_script = wsl_script
        self.wsl_python = wsl_python
        self.sample_rate = sample_rate
        self.distro = distro

        self.process = None

        self.response_queue = queue.Queue()

        self.reader_thread = None
        self.running = False

        self.audio_buffer = bytearray()

        self.last_translation = {
            "translated_text": "",
            "translation_source": None,
            "translation_latency_ms": 0,
            "success": False,
            "error": None,
        }

    # -----------------------------------------------------
    # BUILD WSL COMMAND
    # -----------------------------------------------------

    def _build_command(self):

        if self.distro:

            return [
                "wsl.exe",
                "-d",
                self.distro,
                self.wsl_python,
                self.wsl_script,
            ]

        return [
            "wsl.exe",
            self.wsl_python,
            self.wsl_script,
        ]

    # -----------------------------------------------------
    # READER THREAD
    # -----------------------------------------------------

    def _reader_loop(self):

        while self.running:

            try:

                line = self.process.stdout.readline()

                if not line:
                    break

                # stdout is already decoded as UTF-8
                line = line.strip()

                if not line:
                    continue

                try:

                    response = json.loads(line)

                    self.response_queue.put(response)

                except json.JSONDecodeError:

                    # Ignore non-JSON stdout safely.
                    # Worker logs should normally go to stderr.
                    print(
                        f"[WSL ASR] Invalid JSON response: {line}"
                    )

            except UnicodeDecodeError as e:

                print(
                    "[WSL ASR] UTF-8 decoding error: "
                    f"{e}"
                )

                # Do not kill the whole reader thread.
                continue

            except Exception as e:

                if self.running:

                    print(
                        "[WSL ASR] Reader error: "
                        f"{type(e).__name__}: {e}"
                    )

                break

    # -----------------------------------------------------
    # START WORKER
    # -----------------------------------------------------

    def _start_worker(self):

        if (
            self.process is not None
            and self.process.poll() is None
        ):
            return

        command = self._build_command()

        print("[WSL ASR] Starting worker...")
        print("[WSL ASR] Command:")
        print(" ".join(command))

        self.process = subprocess.Popen(
            command,
            stdin=subprocess.PIPE,

            # IMPORTANT:
            # Explicit UTF-8 prevents Windows cp1252
            # from corrupting Santali Unicode output.
            stdout=subprocess.PIPE,

            stderr=None,

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

        print("[WSL ASR] Waiting for worker...")

        deadline = time.time() + 300

        while time.time() < deadline:

            try:

                response = self.response_queue.get(
                    timeout=0.5
                )

            except queue.Empty:

                if self.process.poll() is not None:

                    raise RuntimeError(
                        "WSL ASR worker exited before becoming ready."
                    )

                continue

            if response.get("type") == "ready":

                print("[WSL ASR] Worker ready.")
                print(
                    f"[WSL ASR] Device: "
                    f"{response.get('device')}"
                )
                print(
                    f"[WSL ASR] Source: "
                    f"{response.get('source_language')}"
                )
                print(
                    f"[WSL ASR] Target: "
                    f"{response.get('target_language')}"
                )

                return

        raise TimeoutError(
            "Timed out waiting for WSL ASR worker."
        )

    # -----------------------------------------------------
    # START STREAM
    # -----------------------------------------------------

    def start_stream(self):

        self._start_worker()

        self.audio_buffer.clear()

        self.last_translation = {
            "translated_text": "",
            "translation_source": None,
            "translation_latency_ms": 0,
            "success": False,
            "error": None,
        }

    # -----------------------------------------------------
    # ACCEPT AUDIO
    # -----------------------------------------------------

    def accept_audio(
        self,
        audio_chunk: bytes
    ) -> bool:

        if not audio_chunk:
            return False

        self.audio_buffer.extend(audio_chunk)

        return False

    # -----------------------------------------------------
    # PARTIAL RESULT
    # -----------------------------------------------------

    def get_partial_result(self) -> ASRResult:

        # Current IndicConformer adapter performs
        # utterance-level inference.
        return ASRResult(
            "",
            False
        )

    # -----------------------------------------------------
    # FINAL RESULT
    # -----------------------------------------------------

    def get_final_result(self) -> ASRResult:

        if not self.audio_buffer:

            return ASRResult(
                "",
                True
            )

        if (
            self.process is None
            or self.process.poll() is not None
        ):

            self._start_worker()

        audio_bytes = bytes(
            self.audio_buffer
        )

        self.audio_buffer.clear()

        audio_b64 = base64.b64encode(
            audio_bytes
        ).decode("ascii")

        request = {
            "type": "transcribe",
            "audio": audio_b64,
        }

        request_json = (
            json.dumps(
                request,
                ensure_ascii=False
            )
            + "\n"
        )

        self.process.stdin.write(
            request_json
        )

        self.process.stdin.flush()

        # Wait for worker result.
        deadline = time.time() + 120

        while time.time() < deadline:

            try:

                response = (
                    self.response_queue.get(
                        timeout=0.5
                    )
                )

            except queue.Empty:

                if self.process.poll() is not None:

                    raise RuntimeError(
                        "WSL ASR worker stopped unexpectedly."
                    )

                continue

            if response.get("type") != "result":
                continue

            self.last_translation = {
                "translated_text":
                    response.get(
                        "translated_text",
                        ""
                    ),

                "translation_source":
                    response.get(
                        "translation_source"
                    ),

                "translation_latency_ms":
                    response.get(
                        "translation_latency_ms",
                        0
                    ),

                "success":
                    response.get(
                        "success",
                        False
                    ),

                "error":
                    response.get(
                        "error"
                    ),
            }

            recognized_text = (
                response.get(
                    "recognized_text",
                    ""
                )
                .strip()
            )

            return ASRResult(
                recognized_text,
                True
            )

        raise TimeoutError(
            "Timed out waiting for ASR result."
        )

    # -----------------------------------------------------
    # STOP STREAM
    # -----------------------------------------------------

    def stop_stream(self):

        self.audio_buffer.clear()

    # -----------------------------------------------------
    # CLOSE WORKER
    # -----------------------------------------------------

    def close(self):

        self.running = False

        if (
            self.process is None
            or self.process.poll() is not None
        ):
            return

        try:

            shutdown_request = (
                json.dumps(
                    {
                        "type": "shutdown"
                    },
                    ensure_ascii=False
                )
                + "\n"
            )

            self.process.stdin.write(
                shutdown_request
            )

            self.process.stdin.flush()

        except Exception:
            pass

        try:

            self.process.wait(
                timeout=10
            )

        except subprocess.TimeoutExpired:

            self.process.kill()

            self.process.wait()

        self.process = None

        print(
            "[WSL ASR] Worker stopped."
        )