"""
PALASH — Standalone WSL TTS → Windows speaker playback test.

Architecture:
  Windows (this script)
    ↓  sends "synthesize" request via JSON IPC
  WSL worker (wsl_asr_worker.py)
    → Indic Parler-TTS synthesizes WAV in WSL/CUDA
    → base64-encodes WAV bytes
    ↓  sends JSON response back via stdout IPC
  Windows (this script)
    → decodes WAV bytes
    → plays through sounddevice on selected device

Parler-TTS runs ONLY in WSL.  Windows plays the received WAV.

Usage:
    python "AI POC/voice/test_wsl_tts_playback.py"
    python "AI POC/voice/test_wsl_tts_playback.py" --device 5
    python "AI POC/voice/test_wsl_tts_playback.py" --device 5 --text "नमस्ते बच्चों" --language sat_Olck
    python "AI POC/voice/test_wsl_tts_playback.py" --list-devices

Environment variable override:
    $env:PALASH_OUTPUT_DEVICE = "5"
"""
import sys
import os
import io
import wave
import argparse
import numpy as np

# -------------------------------------------------------------------
# Project path bootstrap
# -------------------------------------------------------------------
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

DEFAULT_TEXT = "ᱦᱚᱞᱳ ᱜᱤᱫᱽᱨᱟᱹᱠᱚ"
DEFAULT_LANGUAGE = "sat_Olck"


# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

def print_devices():
    """Print all output-capable audio devices to stdout."""
    print("\n+------------------------------------------------------------------+")
    print("|         AVAILABLE AUDIO OUTPUT DEVICES                          |")
    print("+------------------------------------------------------------------+")
    print(f"  {'ID':>3}  {'Default':>7}  {'SR':>6}  {'Ch':>2}  Name")
    print(f"  {'-'*3}  {'-'*7}  {'-'*6}  {'-'*2}  {'-'*45}")

    try:
        default_out_idx = sd.default.device[1]
    except Exception:
        default_out_idx = None

    for idx, dev in enumerate(sd.query_devices()):
        if dev.get("max_output_channels", 0) > 0:
            is_def = (idx == default_out_idx)
            marker = " <-- DEFAULT" if is_def else ""
            print(
                f"  {idx:>3}  {'YES' if is_def else '':>7}  "
                f"{int(dev.get('default_samplerate', 0)):>6}  "
                f"{dev.get('max_output_channels', 0):>2}  "
                f"{dev.get('name', '')}{marker}"
            )
    print()


def diagnose_wav(wav_bytes: bytes) -> dict:
    """
    Parse WAV bytes, compute diagnostics, and return a result dict.
    Returns: {ok, rate, channels, width, n_samples, duration_ms, rms, peak, audio_float32}
    """
    result = {
        "ok": False, "rate": 0, "channels": 0, "width": 0,
        "n_samples": 0, "duration_ms": 0.0, "rms": 0.0, "peak": 0.0,
        "audio_float32": None,
    }

    if not wav_bytes:
        print("[DIAG] ERROR: wav_bytes is empty")
        return result

    if wav_bytes[:4] != b"RIFF" or wav_bytes[8:12] != b"WAVE":
        print(f"[DIAG] ERROR: Not a valid WAV (header: {wav_bytes[:12]!r})")
        return result

    try:
        wav_io = io.BytesIO(wav_bytes)
        with wave.open(wav_io, "rb") as wf:
            channels = wf.getnchannels()
            width    = wf.getsampwidth()
            rate     = wf.getframerate()
            n_frames = wf.getnframes()
            raw_pcm  = wf.readframes(n_frames)

        if width == 2:
            arr = np.frombuffer(raw_pcm, dtype=np.int16).astype(np.float32) / 32768.0
        elif width == 4:
            arr = np.frombuffer(raw_pcm, dtype=np.int32).astype(np.float32) / 2147483648.0
        else:
            print(f"[DIAG] ERROR: Unsupported sample width {width}")
            return result

        if channels > 1:
            arr = arr.reshape(-1, channels)

        flat = arr.ravel()
        n_samples   = len(flat)
        duration_ms = round((n_samples / (rate * channels)) * 1000, 2)
        rms         = float(np.sqrt(np.mean(flat ** 2)))
        peak        = float(np.max(np.abs(flat)))

        result.update({
            "ok": True, "rate": rate, "channels": channels, "width": width,
            "n_samples": n_samples, "duration_ms": duration_ms,
            "rms": rms, "peak": peak,
            "audio_float32": np.clip(arr, -1.0, 1.0),
        })

    except Exception as e:
        print(f"[DIAG] Exception: {e}")

    return result


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="PALASH standalone WSL TTS → Windows speaker playback test"
    )
    parser.add_argument(
        "--device", type=int,
        default=int(os.environ.get("PALASH_OUTPUT_DEVICE", "5")),
        help="sounddevice output device ID (default: 5 = Speakers Realtek, "
             "or $env:PALASH_OUTPUT_DEVICE)"
    )
    parser.add_argument(
        "--text", type=str, default=DEFAULT_TEXT,
        help=f"Text to synthesize (default: {DEFAULT_TEXT!r})"
    )
    parser.add_argument(
        "--language", type=str, default=DEFAULT_LANGUAGE,
        help=f"Language code (default: {DEFAULT_LANGUAGE})"
    )
    parser.add_argument(
        "--list-devices", action="store_true",
        help="List output devices and exit"
    )
    args = parser.parse_args()

    print("=" * 70)
    print("PALASH WSL TTS PLAYBACK TEST")
    print("Architecture: WSL Parler-TTS  ->  IPC WAV  ->  Windows sounddevice")
    print("=" * 70)

    print_devices()

    if args.list_devices:
        sys.exit(0)

    # Identify output device
    device_id = args.device
    try:
        dev_info = sd.query_devices(device_id)
        dev_name = dev_info.get("name", "unknown")
    except Exception:
        dev_name = "unknown"
    print(f"[Test] Output device: [{device_id}] {dev_name}")
    print(f"[Test] Text to synthesize: {args.text!r}")
    print(f"[Test] Language: {args.language}")
    print()

    # -------------------------------------------------------------------
    # Start WSL worker
    # -------------------------------------------------------------------
    print("[Test] Starting WSL worker (loads ASR + Translation + TTS in WSL)...")
    print("[Test] This takes 60-300 seconds on first run (model load).")
    print()

    from voice.wsl_asr_client import WSLIndicConformerASR

    client = WSLIndicConformerASR(
        wsl_script=WSL_WORKER,
        wsl_python=WSL_PYTHON,
    )

    try:
        client._start_worker()
    except Exception as e:
        print(f"[Test ERROR] WSL worker failed to start: {e}")
        sys.exit(1)

    # -------------------------------------------------------------------
    # Request TTS synthesis
    # -------------------------------------------------------------------
    print(f"[Test] Requesting TTS synthesis: {args.text!r} ({args.language})")

    try:
        wav_bytes = client.synthesize(text=args.text, language=args.language)
    except Exception as e:
        print(f"[Test ERROR] synthesize() raised: {e}")
        client.close()
        sys.exit(1)

    # -------------------------------------------------------------------
    # Check result
    # -------------------------------------------------------------------
    meta = client.last_result_metadata
    tts_ms = meta.get("tts_latency_ms", 0)

    print()
    print("[WSL TTS RESULT]")
    print(f"  tts_success:   {meta.get('tts_success')}")
    print(f"  tts_latency:   {tts_ms} ms")
    print(f"  audio_format:  {meta.get('audio_format')}")
    print(f"  error:         {meta.get('error')}")

    if not wav_bytes:
        print()
        print("[Test FAIL] WSL returned no audio bytes.")
        print("  Check: wsl_asr_worker.py stderr for [TTS ERROR] messages.")
        print("  Check: is parler_tts installed in the WSL conda env?")
        client.close()
        sys.exit(1)

    print()
    print(f"[Test] WAV received: YES  ({len(wav_bytes)} bytes)")

    # -------------------------------------------------------------------
    # Diagnose WAV
    # -------------------------------------------------------------------
    diag = diagnose_wav(wav_bytes)

    print()
    print("[TTS AUDIO DIAGNOSTICS]")
    print(f"  WAV bytes:     {len(wav_bytes)}")
    print(f"  Sample rate:   {diag['rate']} Hz")
    print(f"  Channels:      {diag['channels']}")
    print(f"  Sample width:  {diag['width']} bytes ({diag['width']*8}-bit)")
    print(f"  Samples:       {diag['n_samples']}")
    print(f"  Duration:      {diag['duration_ms']} ms")
    print(f"  RMS:           {diag['rms']:.6f}")
    print(f"  Peak:          {diag['peak']:.6f}")

    if not diag["ok"]:
        print()
        print("[Test FAIL] WAV parse failed — cannot play.")
        client.close()
        sys.exit(1)

    if diag["rms"] < 1e-6:
        print()
        print("[Test WARNING] RMS ~ 0.  TTS produced silence.")
        print("  The WAV header is valid but audio content is near-zero.")
        print("  Check Parler model output inside WSL.")

    # -------------------------------------------------------------------
    # Playback
    # -------------------------------------------------------------------
    audio = diag["audio_float32"]
    rate  = diag["rate"]

    print()
    print(f"[Speaker] Device:      [{device_id}] {dev_name}")
    print(f"[Speaker] Sample rate: {rate} Hz")
    print(f"[Speaker] Duration:    {diag['duration_ms']} ms")
    print(f"[Speaker] RMS:         {diag['rms']:.6f}")
    print(f"[Speaker] Peak:        {diag['peak']:.6f}")

    try:
        sd.play(audio, samplerate=rate, device=device_id)
        print("[Speaker] Playback started")
        sd.wait()
        print("[Speaker] Playback completed")
    except Exception as e:
        print(f"[Speaker ERROR] {e}")
        print()
        print("Troubleshooting:")
        print(f"  Try another device:  --device 11  or  --device 13")
        print(f"  List devices:        --list-devices")
        client.close()
        sys.exit(1)

    print()
    print("=" * 70)
    print("[Test] SUCCESS — WSL Parler WAV received and played through Windows speaker.")
    print("=" * 70)

    client.close()


if __name__ == "__main__":
    main()
