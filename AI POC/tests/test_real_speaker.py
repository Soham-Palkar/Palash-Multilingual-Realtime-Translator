"""
PALASH Real Physical Speaker Playback Verification Test

Tests actual physical audio playback through Windows speakers using
synthesized Santali TTS audio for Hindi text: "नमस्ते बच्चों".
"""

import sys
import os
import time

# Ensure UTF-8 output encoding for Windows CMD / PowerShell
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from voice.wsl_asr_client import WSLIndicConformerASR
from voice.audio_output import AudioOutput

WSL_PYTHON = "/home/soham_palkar/miniconda3/envs/palash-translate/bin/python"
WSL_WORKER = (
    "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/"
    "Palash-Multilingual-Realtime-Translator/"
    "AI POC/voice/wsl_asr_worker.py"
)


def run_speaker_playback_test():
    print("=" * 70)
    print("PALASH PHYSICAL SPEAKER PLAYBACK VERIFICATION TEST")
    print("=" * 70)

    # 1. Enumerate Output Devices
    audio_out = AudioOutput()
    devices = audio_out.list_output_devices()
    print("\n[AUDIO DEVICES] Available physical output devices on Windows:")
    for dev in devices:
        default_str = " (DEFAULT)" if dev["is_default"] else ""
        print(f"  [{dev['id']}] {dev['name']} — Channels: {dev['channels']}, Rate: {dev['default_sample_rate']} Hz{default_str}")

    # 2. Connect to WSL worker & generate actual Santali TTS
    print("\n[TTS TEST] Starting WSL Worker process for actual Santali TTS synthesis...")
    asr_client = WSLIndicConformerASR(
        wsl_script=WSL_WORKER,
        wsl_python=WSL_PYTHON,
        source_language="hin_Deva",
        target_language="sat_Olck",
    )

    try:
        asr_client.start_stream()
        test_text = "नमस्ते बच्चों"
        print(f"[TTS TEST] Requesting Santali synthesis for text: '{test_text}'...")

        audio_tts_bytes = asr_client.synthesize("<ctrl42>ᱚᱞᱮ ᱜᱤᱫᱽᱨᱟᱹᱠᱚ ᱾", language="sat_Olck")

        if not audio_tts_bytes:
            print("[TTS TEST] Direct text synthesis returned empty, running full pipeline test...")
            dummy_pcm = b"\x00\x00" * 16000
            asr_client.accept_audio(dummy_pcm)
            res = asr_client.get_final_result(enable_tts=True)
            meta = asr_client.last_result_metadata
            audio_tts_bytes = meta.get("audio_tts")

        if not audio_tts_bytes:
            print("[TTS TEST ERROR] WSL worker returned no TTS audio bytes!")
            return

        sample_rate = 44100  # Parler-TTS default native sample rate
        num_samples = len(audio_tts_bytes) // 2
        duration_s = round(num_samples / sample_rate, 2)

        print("\n" + "=" * 50)
        print("[TTS TEST DIAGNOSTICS]")
        print(f"  Sample Rate:       {sample_rate} Hz")
        print(f"  Channels:          1 (Mono)")
        print(f"  Dtype:             int16 (PCM16)")
        print(f"  Samples:           {num_samples}")
        print(f"  Bytes:             {len(audio_tts_bytes)}")
        print(f"  Duration:          {duration_s} s")
        print("=" * 50 + "\n")

        print("[TTS TEST] Playing generated Santali audio through physical speakers NOW...")
        t0 = time.perf_counter()
        
        play_res = audio_out.play(audio_tts_bytes, sample_rate=sample_rate)

        t_end = time.perf_counter()
        print(f"[TTS TEST] Playback Result: {play_res}")
        print(f"[TTS TEST] Playback Started: {play_res.get('playback_started')}")
        print(f"[TTS TEST] Playback Completed in: {t_end - t0:.2f} s")

    finally:
        asr_client.close()
        audio_out.close()


if __name__ == "__main__":
    run_speaker_playback_test()
