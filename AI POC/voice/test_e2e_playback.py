"""
PALASH End-to-End TTS Playback Test
Sends one sentence through the full WSL pipeline and plays it.

Usage:
    python "AI POC/voice/test_e2e_playback.py"
    python "AI POC/voice/test_e2e_playback.py" --device 4
    python "AI POC/voice/test_e2e_playback.py" --text "नमस्ते" --device 5
"""
import sys
import os
import io
import wave
import argparse
import numpy as np

VOICE_DIR = os.path.dirname(os.path.abspath(__file__))
AI_POC_DIR = os.path.dirname(VOICE_DIR)
if AI_POC_DIR not in sys.path:
    sys.path.insert(0, AI_POC_DIR)

import sounddevice as sd

WSL_PYTHON = "/home/soham_palkar/miniconda3/envs/palash-translate/bin/python"
WSL_WORKER = (
    "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/"
    "Palash-Multilingual-Realtime-Translator/"
    "AI POC/voice/wsl_asr_worker.py"
)


def print_devices():
    print("\nOutput devices:")
    print(f"  {'ID':>3}  {'Default':>7}  Name")
    try:
        default_out = sd.default.device[1]
    except Exception:
        default_out = None
    for idx, dev in enumerate(sd.query_devices()):
        if dev.get("max_output_channels", 0) > 0:
            is_def = (idx == default_out)
            print(f"  {idx:>3}  {'<DEFAULT' if is_def else '':>8}  {dev.get('name', '')}")
    print()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", type=int,
                        default=int(os.environ.get("PALASH_OUTPUT_DEVICE", "5")))
    parser.add_argument("--text", type=str, default="नमस्ते बच्चों")
    parser.add_argument("--language", type=str, default="sat_Olck")
    args = parser.parse_args()

    print("=" * 65)
    print("PALASH END-TO-END TTS PLAYBACK TEST")
    print("=" * 65)
    print_devices()

    print(f"[Config] Output device: {args.device}")
    print(f"[Config] Input text:    {args.text!r}")
    print(f"[Config] TTS language:  {args.language}")
    print()

    # ------------------------------------------------------------------
    # Step 1: Verify the output device works with a beep
    # ------------------------------------------------------------------
    print("[Step 1] Testing output device with 440 Hz beep...")
    t = np.linspace(0, 0.5, int(44100 * 0.5), dtype=np.float32)
    beep = (0.3 * np.sin(2 * np.pi * 440 * t)).astype(np.float32)
    try:
        sd.play(beep, samplerate=44100, device=args.device)
        sd.wait()
        print("[Step 1] PASS — beep played (did you hear it?)")
    except Exception as e:
        print(f"[Step 1] FAIL — {e}")
        print(f"         Try: --device 4  or  --device 13")
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 2: Start WSL worker
    # ------------------------------------------------------------------
    print("\n[Step 2] Starting WSL worker (may take 60-300 s)...")
    from voice.wsl_asr_client import WSLIndicConformerASR

    client = WSLIndicConformerASR(
        wsl_script=WSL_WORKER,
        wsl_python=WSL_PYTHON,
    )
    try:
        client._start_worker()
        print("[Step 2] PASS — worker ready")
    except Exception as e:
        print(f"[Step 2] FAIL — {e}")
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 3: Request synthesis
    # ------------------------------------------------------------------
    print(f"\n[Step 3] Requesting TTS: {args.text!r} -> {args.language}")
    try:
        wav_bytes = client.synthesize(text=args.text, language=args.language)
    except Exception as e:
        print(f"[Step 3] FAIL — synthesize() raised: {e}")
        client.close()
        sys.exit(1)

    meta = client.last_result_metadata
    print(f"[Step 3] tts_success:   {meta.get('tts_success')}")
    print(f"[Step 3] tts_latency:   {meta.get('tts_latency_ms')} ms")
    print(f"[Step 3] audio_format:  {meta.get('audio_format')}")
    print(f"[Step 3] error:         {meta.get('error')}")

    if not wav_bytes:
        print("[Step 3] FAIL — WSL returned no WAV bytes")
        print("         Check: $env:PALASH_OUTPUT_DEVICE stderr for [TTS ERROR]")
        client.close()
        sys.exit(1)

    print(f"[Step 3] PASS — received {len(wav_bytes)} WAV bytes")

    # ------------------------------------------------------------------
    # Step 4: Decode and diagnose WAV
    # ------------------------------------------------------------------
    print("\n[Step 4] Decoding WAV...")
    try:
        buf = io.BytesIO(wav_bytes)
        with wave.open(buf, "rb") as wf:
            channels   = wf.getnchannels()
            width      = wf.getsampwidth()
            rate       = wf.getframerate()
            n_frames   = wf.getnframes()
            raw_pcm    = wf.readframes(n_frames)
        arr = np.frombuffer(raw_pcm, dtype=np.int16).astype(np.float32) / 32768.0
        if channels > 1:
            arr = arr.reshape(-1, channels)
        flat = arr.ravel()
        rms  = float(np.sqrt(np.mean(flat ** 2)))
        peak = float(np.max(np.abs(flat)))
        dur  = round(len(flat) / (rate * channels) * 1000, 1)
        print(f"[Step 4] Sample rate: {rate} Hz")
        print(f"[Step 4] Channels:    {channels}")
        print(f"[Step 4] Duration:    {dur} ms")
        print(f"[Step 4] RMS:         {rms:.6f}  {'<-- SILENT!' if rms < 1e-4 else 'OK'}")
        print(f"[Step 4] Peak:        {peak:.6f}")
        if rms < 1e-4:
            print("[Step 4] WARNING: RMS is near-zero — TTS produced silence")
            print("         The model may not support this language text")
            # still try to play so we can confirm playback layer works
        else:
            print("[Step 4] PASS — audio signal is non-zero")
    except Exception as e:
        print(f"[Step 4] FAIL — WAV decode error: {e}")
        client.close()
        sys.exit(1)

    # ------------------------------------------------------------------
    # Step 5: Play through speaker
    # ------------------------------------------------------------------
    print(f"\n[Step 5] Playing through device {args.device}...")
    arr_clipped = np.clip(arr, -1.0, 1.0)
    try:
        sd.play(arr_clipped, samplerate=rate, device=args.device)
        print("[Step 5] Playback started")
        sd.wait()
        print("[Step 5] Playback completed")
        print("[Step 5] PASS")
    except Exception as e:
        print(f"[Step 5] FAIL — {e}")
        client.close()
        sys.exit(1)

    client.close()

    print()
    print("=" * 65)
    print("RESULT SUMMARY")
    print(f"  Beep test (device {args.device}): PASS")
    print(f"  WSL worker ready:              PASS")
    print(f"  TTS synthesis:                 {'PASS' if wav_bytes else 'FAIL'}")
    print(f"  WAV decode:                    PASS")
    print(f"  Playback:                      PASS")
    print(f"  Audio RMS:                     {rms:.4f}  {'<-- SILENT' if rms < 1e-4 else '(signal present)'}")
    print()
    if rms < 1e-4:
        print("  VERDICT: Playback works but TTS produced silence.")
        print("  The Santali text may not produce audible output with this model.")
    else:
        print("  VERDICT: Full pipeline working — you should have heard Santali voice.")
    print("=" * 65)


if __name__ == "__main__":
    main()
