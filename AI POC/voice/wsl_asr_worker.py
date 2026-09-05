import sys
import json
import base64
import tempfile
import os
import wave
import time
from pathlib import Path

# ---------------------------------------------------------
# IPC PROTOCOL ENFORCEMENT (P0 STRICT RULE)
#
# The raw IPC stdout stream is saved FIRST before any redirect.
# Python-level redirect: sys.stdout = sys.stderr
#   → all Python print() calls go to stderr.
#
# NOTE: os.dup2 is intentionally NOT used here.
# os.dup2(stderr_fd, 1) would destroy fd 1 — which is the Popen stdout=PIPE
# pipe that the Windows client reads from. After dup2, _ipc_stdout_stream.fileno()
# would still be 1 but fd 1 would point to stderr, making all IPC writes
# silently go to stderr instead of the pipe. The Windows reader thread would
# starve and never receive the ready message.
#
# Python-level redirect is sufficient: it covers all Python print() calls.
# C-extension writes to fd 1 are handled by the separate stderr=PIPE capture
# on the Windows client side (non-JSON lines are discarded/logged).
# ---------------------------------------------------------

_ipc_stdout_stream = sys.stdout

# Python level only — do NOT touch fd 1 / os.dup2
sys.stdout = sys.stderr


def send_ipc_response(payload: dict):
    """Write pure un-contaminated JSON response to the IPC stdout stream."""
    json_str = json.dumps(payload, ensure_ascii=False) + "\n"
    _ipc_stdout_stream.write(json_str)
    _ipc_stdout_stream.flush()


import torch
import nemo.collections.asr as nemo_asr
try:
    from nemo.utils import logging as nemo_logging
    nemo_logging.set_verbosity(nemo_logging.ERROR)
except ImportError:
    pass


# ---------------------------------------------------------
# PROJECT PATH
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


from translation.translator import Translator
from voice.indic_parler_tts import IndicParlerTTSBackend


# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

MODEL_NAME = "ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large"
SAMPLE_RATE = 16000
DEFAULT_SOURCE_LANGUAGE = "hin_Deva"
DEFAULT_TARGET_LANGUAGE = "sat_Olck"


# ---------------------------------------------------------
# LOGGING
# ---------------------------------------------------------

def log(message: str):
    """Write debug logs to stderr."""
    print(message, file=sys.stderr, flush=True)


# ---------------------------------------------------------
# MODEL LOADING
# ---------------------------------------------------------

def load_models():
    """
    Load IndicConformer ASR, IndicTrans2 Translator, and Indic Parler-TTS once.
    All models remain loaded in CUDA memory for the lifetime of the worker.
    """
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # 1. ASR
    log(f"[ASR] Loading Hindi model {MODEL_NAME}...")
    log(f"[ASR] Device: {device}")
    asr_start = time.perf_counter()

    asr_model = nemo_asr.models.ASRModel.from_pretrained(MODEL_NAME)
    asr_model.freeze()
    asr_model = asr_model.to(device)
    asr_model.cur_decoder = "ctc"
    asr_model.eval()
    asr_load_ms = round((time.perf_counter() - asr_start) * 1000, 2)
    log(f"[ASR] Ready ({asr_load_ms} ms)")

    # 2. TRANSLATOR
    log("[TRANSLATION] Loading IndicTrans2...")
    trans_start = time.perf_counter()
    translator = Translator()
    trans_load_ms = round((time.perf_counter() - trans_start) * 1000, 2)
    log(f"[TRANSLATION] Ready ({trans_load_ms} ms)")

    # 3. TTS
    log("[TTS] Loading Indic Parler-TTS...")
    tts_start = time.perf_counter()
    tts_backend = None
    try:
        tts_backend = IndicParlerTTSBackend(device=str(device), lazy_load=False)
        tts_load_ms = round((time.perf_counter() - tts_start) * 1000, 2)
        log(f"[TTS] Ready ({tts_load_ms} ms)")
    except Exception as e:
        log(f"[TTS WARNING] Indic Parler-TTS failed to initialize: {e}")
        log("[MODEL MISSING] Run setup/download first.")

    log("[WORKER] Ready")
    return asr_model, translator, tts_backend, device


# ---------------------------------------------------------
# CLEAN ASR RESULT
# ---------------------------------------------------------

def clean_asr_result(raw_result) -> str:
    """Convert raw NeMo result output into clean Hindi text."""
    if raw_result is None:
        return ""

    if isinstance(raw_result, (list, tuple)):
        parts = [str(item).strip() for item in raw_result if item is not None and str(item).strip()]
        text = " ".join(parts)
    else:
        text = str(raw_result).strip()

    if text.startswith("[") and text.endswith("]"):
        text = text[1:-1].strip()
        if len(text) >= 2 and text[0] in ("'", '"') and text[-1] == text[0]:
            text = text[1:-1]

    return text.strip()


# ---------------------------------------------------------
# ASR TRANSCRIBE
# ---------------------------------------------------------

def transcribe(asr_model, pcm_bytes: bytes, language_id: str = "hi") -> tuple[str, float]:
    """Transcribe PCM16 mono 16kHz audio using IndicConformer."""
    if not pcm_bytes:
        return "", 0.0

    temp_path = None
    t0 = time.perf_counter()

    try:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
            temp_path = temp_audio.name

        with wave.open(temp_path, "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(SAMPLE_RATE)
            wav_file.writeframes(pcm_bytes)

        log("[WSL ASR] Running IndicConformer inference...")
        with torch.inference_mode():
            results = asr_model.transcribe(
                [temp_path],
                batch_size=1,
                logprobs=False,
                language_id=language_id,
                verbose=False,
            )

        asr_ms = round((time.perf_counter() - t0) * 1000, 2)

        if not results:
            log("[WSL ASR] No result returned.")
            return "", asr_ms

        text = clean_asr_result(results[0])
        log(f"[WSL ASR] Result ({asr_ms} ms): {text}")
        return text, asr_ms

    finally:
        if temp_path and os.path.exists(temp_path):
            try:
                os.remove(temp_path)
            except OSError as e:
                log(f"[WSL ASR] Warning: Could not remove temp WAV: {e}")


# ---------------------------------------------------------
# TRANSLATION
# ---------------------------------------------------------

def translate_text(translator, text: str, source_lang: str, target_lang: str) -> dict:
    """Translate text using PALASH Translator layer."""
    text = text.strip()

    if not text:
        return {
            "translated_text": "",
            "translation_source": None,
            "latency_ms": 0,
            "success": False,
            "error": "Empty input text for translation"
        }

    log(f"[WSL Translation] Translating ({source_lang} -> {target_lang}): {text}")
    return translator.translate(text, source_lang, target_lang)


# ---------------------------------------------------------
# MAIN WORKER
# ---------------------------------------------------------

def main():
    asr_model, translator, tts_backend, device = load_models()

    # Handshake ready notification to Windows client over pure JSON IPC pipe
    send_ipc_response(
        {
            "type": "ready",
            "model": MODEL_NAME,
            "device": str(device),
            "source_language": DEFAULT_SOURCE_LANGUAGE,
            "target_language": DEFAULT_TARGET_LANGUAGE,
            "tts_available": tts_backend is not None
        }
    )

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            request = json.loads(line)
            request_type = request.get("type")

            if request_type == "transcribe":
                source_lang = request.get("source_language", DEFAULT_SOURCE_LANGUAGE)
                target_lang = request.get("target_language", DEFAULT_TARGET_LANGUAGE)
                enable_tts = request.get("enable_tts", True)
                audio_b64 = request.get("audio", "")

                # Direction validation: Santali ASR check
                if source_lang in ("sat_Olck", "sat"):
                    send_ipc_response(
                        {
                            "type": "result",
                            "recognized_text": "",
                            "translated_text": "",
                            "translation_source": None,
                            "asr_latency_ms": 0,
                            "translation_latency_ms": 0,
                            "tts_latency_ms": 0,
                            "audio_tts": None,
                            "success": False,
                            "error": "Santali ASR pending model integration"
                        }
                    )
                    continue

                if not audio_b64:
                    send_ipc_response(
                        {
                            "type": "result",
                            "recognized_text": "",
                            "translated_text": "",
                            "translation_source": None,
                            "asr_latency_ms": 0,
                            "translation_latency_ms": 0,
                            "tts_latency_ms": 0,
                            "audio_tts": None,
                            "success": False,
                            "error": "No audio data received."
                        }
                    )
                    continue

                try:
                    pcm_bytes = base64.b64decode(audio_b64)
                except Exception as e:
                    send_ipc_response(
                        {
                            "type": "result",
                            "recognized_text": "",
                            "translated_text": "",
                            "translation_source": None,
                            "asr_latency_ms": 0,
                            "translation_latency_ms": 0,
                            "tts_latency_ms": 0,
                            "audio_tts": None,
                            "success": False,
                            "error": f"Invalid audio data: {e}"
                        }
                    )
                    continue

                log(f"[WSL ASR] Received audio frame: {len(pcm_bytes)} bytes")

                # 1. ASR
                recognized_text, asr_ms = transcribe(asr_model, pcm_bytes, language_id="hi")

                if not recognized_text:
                    send_ipc_response(
                        {
                            "type": "result",
                            "recognized_text": "",
                            "translated_text": "",
                            "translation_source": None,
                            "asr_latency_ms": asr_ms,
                            "translation_latency_ms": 0,
                            "tts_latency_ms": 0,
                            "audio_tts": None,
                            "success": False,
                            "error": "ASR returned empty text."
                        }
                    )
                    continue

                # 2. Translation
                translation_result = translate_text(translator, recognized_text, source_lang, target_lang)
                translated_text = translation_result.get("translated_text", "")
                trans_ms = translation_result.get("latency_ms", 0)

                # 3. TTS
                audio_tts_b64 = None
                tts_ms = 0.0

                if enable_tts and translated_text and tts_backend:
                    t_tts_start = time.perf_counter()
                    pcm_tts = tts_backend.synthesize(translated_text, language=target_lang)
                    tts_ms = round((time.perf_counter() - t_tts_start) * 1000, 2)

                    if pcm_tts:
                        audio_tts_b64 = base64.b64encode(pcm_tts).decode("ascii")

                # Send complete pipeline result to Windows client over pure JSON IPC pipe
                send_ipc_response(
                    {
                        "type": "result",
                        "recognized_text": recognized_text,
                        "translated_text": translated_text,
                        "translation_source": translation_result.get("translation_source"),
                        "asr_latency_ms": asr_ms,
                        "translation_latency_ms": trans_ms,
                        "tts_latency_ms": tts_ms,
                        "tts_success": audio_tts_b64 is not None,
                        "audio_format": "wav" if audio_tts_b64 else None,
                        "audio_base64": audio_tts_b64,
                        # Legacy field kept for backwards compat
                        "audio_tts": audio_tts_b64,
                        "success": translation_result.get("success", False),
                        "error": translation_result.get("error")
                    }
                )

            elif request_type == "synthesize":
                text = request.get("text", "").strip()
                lang = request.get("language", DEFAULT_TARGET_LANGUAGE)
                audio_tts_b64 = None
                tts_ms = 0.0
                err = None

                if text and tts_backend:
                    t_tts_start = time.perf_counter()
                    pcm_tts = tts_backend.synthesize(text, language=lang)
                    tts_ms = round((time.perf_counter() - t_tts_start) * 1000, 2)
                    if pcm_tts:
                        audio_tts_b64 = base64.b64encode(pcm_tts).decode("ascii")
                    else:
                        err = "TTS synthesis returned None"
                else:
                    err = "Empty text or TTS backend unavailable"

                send_ipc_response(
                    {
                        "type": "result",
                        "recognized_text": "",
                        "translated_text": text,
                        "translation_source": "direct_tts",
                        "asr_latency_ms": 0,
                        "translation_latency_ms": 0,
                        "tts_latency_ms": tts_ms,
                        "tts_success": audio_tts_b64 is not None,
                        "audio_format": "wav" if audio_tts_b64 else None,
                        "audio_base64": audio_tts_b64,
                        # Legacy field kept for backwards compat
                        "audio_tts": audio_tts_b64,
                        "success": audio_tts_b64 is not None,
                        "error": err
                    }
                )

            elif request_type == "shutdown":
                log("[WSL Worker] Shutdown requested.")
                send_ipc_response({"type": "shutdown", "success": True})
                break

            else:
                send_ipc_response(
                    {
                        "type": "error",
                        "success": False,
                        "error": f"Unknown request type: {request_type}"
                    }
                )

        except Exception as e:
            log(f"[WSL Worker] Exception: {type(e).__name__}: {e}")
            send_ipc_response(
                {
                    "type": "result",
                    "recognized_text": "",
                    "translated_text": "",
                    "translation_source": None,
                    "asr_latency_ms": 0,
                    "translation_latency_ms": 0,
                    "tts_latency_ms": 0,
                    "audio_tts": None,
                    "success": False,
                    "error": str(e)
                }
            )


if __name__ == "__main__":
    main()