import sys
import os
import time

# Project path
VOICE_DIR = os.path.dirname(os.path.abspath(__file__))
AI_POC_DIR = os.path.dirname(VOICE_DIR)

if AI_POC_DIR not in sys.path:
    sys.path.insert(0, AI_POC_DIR)

from voice.voice_pipeline import VoicePipeline
from voice.wsl_asr_client import WSLIndicConformerASR
from voice.audio_output import AudioOutput


# -----------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------

SAMPLE_RATE = 16000

WSL_PYTHON = "/home/soham_palkar/miniconda3/envs/palash-translate/bin/python"
WSL_WORKER = (
    "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/"
    "Palash-Multilingual-Realtime-Translator/"
    "AI POC/voice/wsl_asr_worker.py"
)

# Output device selection:
#   Set env var PALASH_OUTPUT_DEVICE to override the system default.
#   Example (PowerShell):
#     $env:PALASH_OUTPUT_DEVICE = "5"   # Speakers (Realtek)
#     python "AI POC\voice\realtime_translation.py"
#
# Device map (from sd.query_devices() on this machine):
#   3  Microsoft Sound Mapper - Output  (MME, default mapper)
#   4  Headphones (Realtek(R) Audio)    (MME) ← system default
#   5  Speakers  (Realtek(R) Audio)     (MME)
#  12  Headphones (Realtek(R) Audio)    (WASAPI)
#  13  Speakers  (Realtek(R) Audio)     (WASAPI)
_env_device = os.environ.get("PALASH_OUTPUT_DEVICE", "").strip()
OUTPUT_DEVICE_ID: int = int(_env_device) if _env_device.isdigit() else 5


def main():
    print("=" * 70)
    print("PALASH REAL-TIME OFFLINE VOICE TRANSLATION")
    print("Teacher Mode: Hindi (Speech) -> Santali (Speech)")
    print(f"Output device: {OUTPUT_DEVICE_ID}  "
          f"(override with $env:PALASH_OUTPUT_DEVICE)")
    print("=" * 70)

    # Initialize AudioOutput with the selected speaker device
    audio_out = AudioOutput(device_id=OUTPUT_DEVICE_ID)
    audio_out.print_output_devices()

    # Initialize WSL ASR + Translation + TTS client
    asr_client = WSLIndicConformerASR(
        wsl_script=WSL_WORKER,
        wsl_python=WSL_PYTHON,
        sample_rate=SAMPLE_RATE,
        source_language="hin_Deva",
        target_language="sat_Olck",
    )

    pipeline = VoicePipeline(
        source_language="hin_Deva",
        target_language="sat_Olck",
        asr_engine=asr_client,
        audio_output=audio_out,
        energy_threshold=800,
        sample_rate=SAMPLE_RATE,
    )

    try:
        pipeline.start()
    except KeyboardInterrupt:
        print("\n[Main] Interrupted by user.")
    except Exception as e:
        print(f"\n[Main ERROR] {e}")
    finally:
        pipeline.stop()


if __name__ == "__main__":
    main()
