import sounddevice as sd
import soundfile as sf

OUTPUT = "test_hindi.wav"
SAMPLE_RATE = 16000
DURATION = 5

print("Recording...")
print("Speak Hindi now!")

audio = sd.rec(
    int(DURATION * SAMPLE_RATE),
    samplerate=SAMPLE_RATE,
    channels=1,
    dtype="float32"
)

sd.wait()

sf.write(OUTPUT, audio, SAMPLE_RATE)

print(f"Saved: {OUTPUT}")