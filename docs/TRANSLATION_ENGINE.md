# PALASH Translation Engine

## Owner

M2

## Purpose

Hindi ↔ Santali translation layer.

## Current model

IndicTrans2 Indic-Indic Distilled 320M.

## Language codes

Hindi:
`hin_Deva`

Santali:
`sat_Olck`

## Directions

Hindi → Santali
Santali → Hindi

## Development environment

Ubuntu / WSL2
Python 3.11
Conda environment:
palash-translate

## Dependencies

- torch
- transformers
- IndicTransToolkit

## How to run

Provide exact commands.

Example:

    conda activate palash-translate
    cd "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/Palash-Multilingual-Realtime-Translator/AI POC"
    python translation_baseline.py

And:

    python benchmarks/benchmark_translation.py

## Architecture

ASR
↓
Translation API
↓
IndicTrans2 (with lightweight phrase matching)
↓
TTS

The Translation API handles caching (phrase matching) and context mapping (if provided). Neural machine translation kicks in for unknown phrases.

## Input format

UTF-8 text.

## Output format

Structured JSON-like result.

## Model loading

The model, tokenizer, and `IndicProcessor` are loaded exactly **once** upon initializing the `Translator` class. This approach prevents extreme latency overhead during real-time inferences.

## Performance

Model size:
~1.28 GB (distilled 320M model)

RAM:
TBD (Needs measurement)

Average latency:
870.76 ms

P50:
645.00 ms

P95:
950.35 ms

P99:
7290.09 ms

Maximum latency:
13248.00 ms

## Quality

BLEU:
TBD

chrF:
TBD

Human evaluation:
TBD

## Known limitations

- Santali is low-resource.
- Translation quality requires native-speaker validation.
- Current development model is not yet Android optimized.
- Current runtime is Python/PyTorch.
- M4 must optimize for low-RAM Android.

## Android handoff requirements

M4 should investigate:
- CTranslate2
- ONNX where appropriate
- INT8 quantization
- ARM64
- memory optimization
- offline model packaging
