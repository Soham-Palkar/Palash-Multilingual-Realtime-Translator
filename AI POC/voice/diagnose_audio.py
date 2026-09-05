"""
PALASH Audio Diagnostic — tests every layer of the playback path
without requiring the WSL worker or Parler-TTS model.

Run from the project root:
    python "AI POC/voice/diagnose_audio.py"

What it checks:
  1. sounddevice import and device list
  2. Which device id is currently configured (OUTPUT_DEVICE_ID)
  3. Plays a 1-second 440 Hz sine tone directly through sounddevice
  4. Builds a valid WAV in memory and plays it via AudioOutput.play()
  5. Reports exactly where a failure occurs
"""
import sys
import os
import io
import wave
import struct
import math

VOICE_DIR = os.path.dirname(os.path.abspath(__file__))
AI_POC_DIR = os.path.dirname(VOICE_DIR)
if AI_POC_DIR not in sys.path:
    sys.path.insert(0, AI_POC_DIR)

import numpy as np
import sounddevice as sd

# -----------------------------------------------------------------------
# Read the same device id that realtime_translation.py uses
# -----------------------------------------------------------------------
_env = os.environ.get("PALASH_OUTPUT_DEVICE", "").strip()
OUTPUT_DEVICE_ID = int(_env) if _env.isdigit() else 5

SAMPLE_RATE = 44100
DURATION_S  = 1.0

print("=" * 60)
print("PALASH AUDIO DIAGNOSTIC")
print("=" * 60)

# -----------------------------------------------------------------------
# 1. List all output devices
# -----------------------------------------------------------------------
print("\n[1] Output devices:")
print(f"  {'ID':>3}  {'Default':>7}  {'SR':>6}  {'Ch':>2}  Name")
print(f"  {'-'*3}  {'-'*7}  {'-'*6}  {'-'*2}  {'-'*40}")
try:
    default_out = sd.default.device[1]
except Exception:
    default_out = None

output_ids = []
for idx, dev in enumerate(sd.query_devices()):
    if dev.get("max_output_channels", 0) > 0:
        output_ids.append(idx)
        is_def = (idx == default_out)
        marker = " <-- DEFAULT" if is_def else ""
        print(
            f"  {idx:>3}  {'YES' if is_def else '':>7}  "
            f"{int(dev.get('default_samplerate', 0)):>6}  "
            f"{dev.get('max_output_channels', 0):>2}  "
            f"{dev.get('name', '')}{marker}"
        )

# -----------------------------------------------------------------------
# 2. Confirm configured device
# -----------------------------------------------------------------------
print(f"\n[2] Configured OUTPUT_DEVICE_ID = {OUTPUT_DEVICE_ID}")
if OUTPUT_DEVICE_ID not in output_ids:
    print(f"    WARNING: device {OUTPUT_DEVICE_ID} is NOT in the output device list!")
    print(f"    Run with: $env:PALASH_OUTPUT_DEVICE='<id>'")
    print(f"    Valid output IDs: {output_ids}")
else:
    dev_info = sd.query_devices(OUTPUT_DEVICE_ID)
    print(f"    Device name:  {dev_info.get('name')}")
    print(f"    Max channels: {dev_info.get('max_output_channels')}")
    print(f"    Default SR:   {int(dev_info.get('default_samplerate', 0))} Hz")

# -----------------------------------------------------------------------
# 3. Direct sd.play() with 440 Hz sine tone
# -----------------------------------------------------------------------
print(f"\n[3] Direct sounddevice sine tone test (device={OUTPUT_DEVICE_ID}, 440 Hz, 1 s)...")
t = np.linspace(0, DURATION_S, int(SAMPLE_RATE * DURATION_S), endpoint=False, dtype=np.float32)
tone = (0.4 * np.sin(2 * math.pi * 440 * t)).astype(np.float32)

try:
    sd.play(tone, samplerate=SAMPLE_RATE, device=OUTPUT_DEVICE_ID)
    sd.wait()
    print("    --> Did you hear a beep? (Y/N)")
    print("    [3] PASSED — sd.play() completed without exception")
except Exception as e:
    print(f"    [3] FAILED: {e}")
    print(f"    Try a different device id: $env:PALASH_OUTPUT_DEVICE='<id>'")
    sys.exit(1)

# -----------------------------------------------------------------------
# 4. AudioOutput.play() with a synthetic WAV
# -----------------------------------------------------------------------
print(f"\n[4] AudioOutput.play() with synthetic WAV (440 Hz, 1 s)...")

# Build a valid PCM16 WAV in memory
pcm16 = (tone * 32767).astype(np.int16)
wav_buf = io.BytesIO()
with wave.open(wav_buf, "wb") as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(pcm16.tobytes())
wav_bytes = wav_buf.getvalue()

print(f"    Synthetic WAV: {len(wav_bytes)} bytes, {SAMPLE_RATE} Hz, 1 ch, 16-bit")

from voice.audio_output import AudioOutput
ao = AudioOutput(device_id=OUTPUT_DEVICE_ID)
result = ao.play(wav_bytes)

print(f"    Result: {result}")
if result.get("success"):
    print("    --> Did you hear the second beep?")
    print("    [4] PASSED — AudioOutput.play() succeeded")
else:
    print(f"    [4] FAILED: {result.get('error')}")
    sys.exit(1)

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
print()
print("=" * 60)
print("DIAGNOSTIC COMPLETE")
print(f"  sounddevice:       OK")
print(f"  output device:     [{OUTPUT_DEVICE_ID}] {sd.query_devices(OUTPUT_DEVICE_ID).get('name')}")
print(f"  direct sd.play():  OK")
print(f"  AudioOutput.play(): OK")
print()
print("If you heard both beeps: the playback path is working.")
print("If you heard nothing:    check Windows volume / device selection.")
print("=" * 60)
