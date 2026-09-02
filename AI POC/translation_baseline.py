import torch

from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from IndicTransToolkit.processor import IndicProcessor


MODEL_NAME = "ai4bharat/indictrans2-indic-indic-dist-320M"

SRC_LANG = "hin_Deva"
TGT_LANG = "sat_Olck"


print("=" * 60)
print("PALASH - Hindi → Santali Translation POC")
print("=" * 60)

# ---------------------------------------------------------
# Device
# ---------------------------------------------------------

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

print("\nDevice:", DEVICE)

# ---------------------------------------------------------
# Load tokenizer
# ---------------------------------------------------------

print("\nLoading tokenizer...")

tokenizer = AutoTokenizer.from_pretrained(
    MODEL_NAME,
    trust_remote_code=True
)

# ---------------------------------------------------------
# Load model
# ---------------------------------------------------------

print("Loading model...")

model = AutoModelForSeq2SeqLM.from_pretrained(
    MODEL_NAME,
    trust_remote_code=True
)

model = model.to(DEVICE)

# ---------------------------------------------------------
# Indic processor
# ---------------------------------------------------------

ip = IndicProcessor(inference=True)

print("Model loaded successfully.")

# ---------------------------------------------------------
# Test sentence
# ---------------------------------------------------------

input_sentences = [
    "बच्चों, इसे सुरक्षित रूप से खेलें।"
]

print("\nHindi:")
print(input_sentences[0])

# ---------------------------------------------------------
# Preprocess
# ---------------------------------------------------------

batch = ip.preprocess_batch(
    input_sentences,
    src_lang=SRC_LANG,
    tgt_lang=TGT_LANG,
)

# ---------------------------------------------------------
# Tokenization
# ---------------------------------------------------------

inputs = tokenizer(
    batch,
    truncation=True,
    padding="longest",
    return_tensors="pt",
    return_attention_mask=True,
).to(DEVICE)

# ---------------------------------------------------------
# Translation
# ---------------------------------------------------------

print("\nTranslating...")

with torch.no_grad():

    generated_tokens = model.generate(
        **inputs,
        use_cache=True,
        min_length=0,
        max_length=256,
        num_beams=5,
        num_return_sequences=1,
    )

# ---------------------------------------------------------
# Decode
# ---------------------------------------------------------

translations = tokenizer.batch_decode(
    generated_tokens,
    skip_special_tokens=True,
    clean_up_tokenization_spaces=True,
)

# ---------------------------------------------------------
# Postprocess
# ---------------------------------------------------------

translations = ip.postprocess_batch(
    translations,
    lang=TGT_LANG,
)

# ---------------------------------------------------------
# Output
# ---------------------------------------------------------

print("\nSantali:")
print(translations[0])

print("\n" + "=" * 60)
print("Translation completed.")
print("=" * 60)