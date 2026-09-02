import torch
import nemo.collections.asr as nemo_asr


MODEL_NAME = "ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large"
AUDIO_FILE = "test_hindi.wav"


print("Loading IndicConformer Hindi model...")

model = nemo_asr.models.ASRModel.from_pretrained(MODEL_NAME)

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

model.freeze()
model = model.to(device)

print("Model loaded successfully!")
print(f"Device: {device}")

# Use CTC decoder
model.cur_decoder = "ctc"

print("\nTranscribing...")
result = model.transcribe(
    [AUDIO_FILE],
    batch_size=1,
    logprobs=False,
    language_id="hi"
)

print("\n==============================")
print("Recognized Hindi:")
print(result[0])
print("==============================")