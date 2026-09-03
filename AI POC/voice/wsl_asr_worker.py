import sys
import json
import base64
import tempfile
import os
import wave
from pathlib import Path

import torch
import nemo.collections.asr as nemo_asr


# ---------------------------------------------------------
# PROJECT PATH
# ---------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[1]

if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


from translation.translator import Translator


# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------

MODEL_NAME = (
    "ai4bharat/"
    "indicconformer_stt_hi_hybrid_rnnt_large"
)

SAMPLE_RATE = 16000

SOURCE_LANGUAGE = "hin_Deva"
TARGET_LANGUAGE = "sat_Olck"


# ---------------------------------------------------------
# LOGGING
# ---------------------------------------------------------

def log(message: str):
    """
    Write logs to stderr.

    stdout is reserved for JSON communication
    with the Windows client.
    """

    print(
        message,
        file=sys.stderr,
        flush=True
    )


# ---------------------------------------------------------
# MODEL LOADING
# ---------------------------------------------------------

def load_models():
    """
    Load IndicConformer ASR and PALASH Translator.

    Both remain loaded for the lifetime of this worker.
    """

    device = torch.device(
        "cuda"
        if torch.cuda.is_available()
        else "cpu"
    )

    # -----------------------------------------------------
    # ASR
    # -----------------------------------------------------

    log(
        "[WSL ASR] Loading "
        f"{MODEL_NAME}"
    )

    log(
        f"[WSL ASR] Device: {device}"
    )

    asr_model = (
        nemo_asr.models.ASRModel
        .from_pretrained(MODEL_NAME)
    )

    asr_model.freeze()

    asr_model = asr_model.to(device)

    # Use CTC decoder for current pipeline.
    asr_model.cur_decoder = "ctc"

    log(
        "[WSL ASR] IndicConformer "
        "loaded successfully."
    )

    # -----------------------------------------------------
    # TRANSLATOR
    # -----------------------------------------------------

    log(
        "[WSL Translation] "
        "Loading Translator..."
    )

    translator = Translator()

    log(
        "[WSL Translation] "
        "Translator loaded successfully."
    )

    return asr_model, translator, device


# ---------------------------------------------------------
# CLEAN ASR RESULT
# ---------------------------------------------------------

def clean_asr_result(raw_result) -> str:
    """
    Convert the different result formats returned by
    NeMo into clean Hindi text.

    Examples:

        ['मेरा नाम सोहम है']
            ->
        मेरा नाम सोहम है

        "मेरा नाम सोहम है"
            ->
        मेरा नाम सोहम है

        ['मेरा', 'नाम', 'सोहम', 'है']
            ->
        मेरा नाम सोहम है
    """

    if raw_result is None:
        return ""

    # -----------------------------------------------------
    # Actual list/tuple returned by NeMo
    # -----------------------------------------------------

    if isinstance(raw_result, (list, tuple)):

        parts = []

        for item in raw_result:

            if item is None:
                continue

            item_text = str(item).strip()

            if item_text:
                parts.append(item_text)

        text = " ".join(parts)

    else:

        text = str(raw_result).strip()

    text = text.strip()

    # -----------------------------------------------------
    # Handle string representation of a Python list
    #
    # Example:
    # "['मेरा नाम सोहम है']"
    # -----------------------------------------------------

    if (
        text.startswith("[")
        and text.endswith("]")
    ):

        text = text[1:-1].strip()

        # Remove surrounding single quotes.
        if (
            len(text) >= 2
            and text.startswith("'")
            and text.endswith("'")
        ):
            text = text[1:-1]

        # Remove surrounding double quotes.
        elif (
            len(text) >= 2
            and text.startswith('"')
            and text.endswith('"')
        ):
            text = text[1:-1]

    return text.strip()


# ---------------------------------------------------------
# ASR
# ---------------------------------------------------------

def transcribe(
    asr_model,
    pcm_bytes: bytes
) -> str:
    """
    Transcribe PCM16 mono 16kHz audio.

    Input:
        Raw PCM16 bytes.

    Output:
        Recognized Hindi text.
    """

    if not pcm_bytes:
        return ""

    temp_path = None

    try:

        # -------------------------------------------------
        # Create temporary WAV for NeMo
        # -------------------------------------------------

        with tempfile.NamedTemporaryFile(
            suffix=".wav",
            delete=False
        ) as temp_audio:

            temp_path = temp_audio.name

        with wave.open(
            temp_path,
            "wb"
        ) as wav_file:

            wav_file.setnchannels(1)

            # PCM16 = 2 bytes/sample
            wav_file.setsampwidth(2)

            wav_file.setframerate(
                SAMPLE_RATE
            )

            wav_file.writeframes(
                pcm_bytes
            )

        # -------------------------------------------------
        # IndicConformer inference
        # -------------------------------------------------

        log(
            "[WSL ASR] Running "
            "IndicConformer inference..."
        )

        results = asr_model.transcribe(
            [temp_path],
            batch_size=1,
            logprobs=False,
            language_id="hi",
            verbose=False,
        )

        if not results:
            log("[WSL ASR] No result returned.")
            return ""

        # -------------------------------------------------
        # CLEAN NE Mo RESULT
        # -------------------------------------------------

        raw_result = results[0]

        text = clean_asr_result(
            raw_result
        )

        log(
            f"[WSL ASR] Result: {text}"
        )

        return text

    finally:

        # -------------------------------------------------
        # Remove temporary WAV
        # -------------------------------------------------

        if (
            temp_path
            and os.path.exists(temp_path)
        ):

            try:
                os.remove(temp_path)

            except OSError as e:

                log(
                    "[WSL ASR] Warning: "
                    f"Could not remove temporary WAV: {e}"
                )


# ---------------------------------------------------------
# TRANSLATION
# ---------------------------------------------------------

def translate_text(
    translator,
    text: str
):
    """
    Translate Hindi text to Santali
    using the existing PALASH translation layer.
    """

    text = text.strip()

    if not text:

        return {
            "translated_text": "",
            "translation_source": None,
            "latency_ms": 0,
            "success": False,
            "error": "Empty ASR text"
        }

    log(
        "[WSL Translation] "
        f"Translating: {text}"
    )

    result = translator.translate(
        text,
        SOURCE_LANGUAGE,
        TARGET_LANGUAGE
    )

    if result["success"]:

        log(
            "[WSL Translation] "
            f"Result: "
            f"{result['translated_text']}"
        )

    else:

        log(
            "[WSL Translation] "
            f"FAILED: {result['error']}"
        )

    return result


# ---------------------------------------------------------
# MAIN WORKER
# ---------------------------------------------------------

def main():

    # -----------------------------------------------------
    # Load models ONCE
    # -----------------------------------------------------

    asr_model, translator, device = (
        load_models()
    )

    # -----------------------------------------------------
    # Tell Windows worker is ready
    # -----------------------------------------------------

    print(
        json.dumps(
            {
                "type": "ready",
                "model": MODEL_NAME,
                "device": str(device),
                "source_language": SOURCE_LANGUAGE,
                "target_language": TARGET_LANGUAGE
            },
            ensure_ascii=False
        ),
        flush=True
    )

    # -----------------------------------------------------
    # Wait for Windows requests
    # -----------------------------------------------------

    for line in sys.stdin:

        line = line.strip()

        if not line:
            continue

        try:

            request = json.loads(line)

            request_type = request.get(
                "type"
            )

            # =================================================
            # TRANSCRIBE + TRANSLATE
            # =================================================

            if request_type == "transcribe":

                audio_b64 = request.get(
                    "audio",
                    ""
                )

                if not audio_b64:

                    print(
                        json.dumps(
                            {
                                "type": "result",
                                "recognized_text": "",
                                "translated_text": "",
                                "translation_source": None,
                                "translation_latency_ms": 0,
                                "success": False,
                                "error": (
                                    "No audio data received."
                                )
                            },
                            ensure_ascii=False
                        ),
                        flush=True
                    )

                    continue

                # -----------------------------------------
                # Decode audio
                # -----------------------------------------

                try:

                    pcm_bytes = base64.b64decode(
                        audio_b64
                    )

                except Exception as e:

                    print(
                        json.dumps(
                            {
                                "type": "result",
                                "recognized_text": "",
                                "translated_text": "",
                                "translation_source": None,
                                "translation_latency_ms": 0,
                                "success": False,
                                "error": (
                                    f"Invalid audio data: {e}"
                                )
                            },
                            ensure_ascii=False
                        ),
                        flush=True
                    )

                    continue

                log(
                    "[WSL ASR] Received "
                    f"{len(pcm_bytes)} bytes"
                )

                # -----------------------------------------
                # ASR
                # -----------------------------------------

                recognized_text = transcribe(
                    asr_model,
                    pcm_bytes
                )

                if not recognized_text:

                    print(
                        json.dumps(
                            {
                                "type": "result",
                                "recognized_text": "",
                                "translated_text": "",
                                "translation_source": None,
                                "translation_latency_ms": 0,
                                "success": False,
                                "error": (
                                    "ASR returned empty text."
                                )
                            },
                            ensure_ascii=False
                        ),
                        flush=True
                    )

                    continue

                # -----------------------------------------
                # Translation
                # -----------------------------------------

                translation_result = (
                    translate_text(
                        translator,
                        recognized_text
                    )
                )

                # -----------------------------------------
                # Return result to Windows
                # -----------------------------------------

                print(
                    json.dumps(
                        {
                            "type": "result",

                            "recognized_text":
                                recognized_text,

                            "translated_text":
                                translation_result.get(
                                    "translated_text",
                                    ""
                                ),

                            "translation_source":
                                translation_result.get(
                                    "translation_source"
                                ),

                            "translation_latency_ms":
                                translation_result.get(
                                    "latency_ms",
                                    0
                                ),

                            "success":
                                translation_result.get(
                                    "success",
                                    False
                                ),

                            "error":
                                translation_result.get(
                                    "error"
                                )
                        },
                        ensure_ascii=False
                    ),
                    flush=True
                )

            # =================================================
            # SHUTDOWN
            # =================================================

            elif request_type == "shutdown":

                log(
                    "[WSL ASR] "
                    "Shutdown requested."
                )

                print(
                    json.dumps(
                        {
                            "type": "shutdown",
                            "success": True
                        },
                        ensure_ascii=False
                    ),
                    flush=True
                )

                break

            # =================================================
            # UNKNOWN REQUEST
            # =================================================

            else:

                print(
                    json.dumps(
                        {
                            "type": "error",
                            "success": False,
                            "error": (
                                "Unknown request type: "
                                f"{request_type}"
                            )
                        },
                        ensure_ascii=False
                    ),
                    flush=True
                )

        except Exception as e:

            log(
                "[WSL Worker] Error: "
                f"{type(e).__name__}: {e}"
            )

            print(
                json.dumps(
                    {
                        "type": "result",
                        "recognized_text": "",
                        "translated_text": "",
                        "translation_source": None,
                        "translation_latency_ms": 0,
                        "success": False,
                        "error": str(e)
                    },
                    ensure_ascii=False
                ),
                flush=True
            )


# ---------------------------------------------------------
# ENTRY POINT
# ---------------------------------------------------------

if __name__ == "__main__":
    main()