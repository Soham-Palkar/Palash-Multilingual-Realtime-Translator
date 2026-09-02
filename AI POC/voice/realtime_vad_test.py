import sounddevice as sd
import numpy as np
import time

DEVICE = 1
SAMPLE_RATE = 16000
CHANNELS = 1
BLOCK_SIZE = 1600       # 100 ms
ENERGY_THRESHOLD = 0.02
SILENCE_DURATION = 0.8

last_speech_time = None
speaking = False


def callback(indata, frames, time_info, status):
    global last_speech_time, speaking

    if status:
        print("STATUS:", status)

    audio = indata[:, 0].astype(np.float32)

    rms = np.sqrt(np.mean(audio ** 2))
    now = time.time()

    if rms >= ENERGY_THRESHOLD:
        last_speech_time = now

        if not speaking:
            speaking = True
            print("\n🟢 SPEECH DETECTED")

    elif speaking and last_speech_time is not None:
        if now - last_speech_time >= SILENCE_DURATION:
            speaking = False
            print("\n🔴 END OF SPEECH")


print("=" * 60)
print("PALASH REAL-TIME VAD TEST")
print("=" * 60)
print(f"Microphone device: {DEVICE}")
print(f"Sample rate: {SAMPLE_RATE} Hz")
print(f"Energy threshold: {ENERGY_THRESHOLD}")
print("\nSpeak normally. Press Ctrl+C to stop.\n")

try:
    with sd.InputStream(
        device=DEVICE,
        samplerate=SAMPLE_RATE,
        channels=CHANNELS,
        dtype="float32",
        blocksize=BLOCK_SIZE,
        callback=callback,
    ):
        while True:
            sd.sleep(1000)

except KeyboardInterrupt:
    print("\nStopped.")