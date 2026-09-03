# M2 HANDOVER — PALASH TRANSLATION

## 1. Current Status

| Component | Status |
|-----------|--------|
| Translation (Hindi → Santali) | DONE |
| Translation (Santali → Hindi) | DONE |
| Phrase bank | DONE |
| Context layer | IN PROGRESS (API supports it, logic TBD) |
| Translation benchmark | DONE |
| Voice pipeline architecture | DONE |
| Microphone capture | BLOCKED (WSL audio passthrough not configured) |
| VAD | DONE (energy-based) |
| ASR interface | DONE (Vosk backend + Dummy) |
| TTS interface | DONE (Piper backend + Dummy). Santali voice: BLOCKED |
| Voice pipeline integration | DONE (code complete, requires mic fix to test) |
| Optimization (PyTorch INT8) | DONE — measured, slower on CPU |
| Optimization (CTranslate2) | TODO — package not installed |
| Optimization (ONNX) | TODO — package not installed |
| Android deployment | TODO (M4) |

## 2. Working Environment

- **OS**: Ubuntu / WSL2
- **Conda environment**: `palash-translate`
- **Python version**: 3.11
- **Key packages**: torch, transformers, IndicTransToolkit, pyaudio, psutil

## 3. How to Run

```bash
conda activate palash-translate
cd "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/Palash-Multilingual-Realtime-Translator/AI POC"

# Translation tests
python tests/test_translation.py

# Translation benchmark (50 sentences)
python benchmarks/benchmark_translation.py

# Optimization benchmark (INT8, CT2, ONNX)
python benchmarks/benchmark_optimization.py

# Microphone diagnostic
python voice/test_microphone.py

# Full voice pipeline (requires working microphone)
python voice/voice_pipeline.py --source hin_Deva --target sat_Olck
```

## 4. Important Files

| File | Purpose |
|------|---------|
| `translation/translator.py` | Main translation engine |
| `translation/languages.py` | Language configuration |
| `translation_baseline.py` | Known-working reference baseline |
| `voice/microphone.py` | Real-time microphone capture |
| `voice/audio_buffer.py` | Thread-safe PCM buffer |
| `voice/vad.py` | Energy-based voice activity detection |
| `voice/asr_interface.py` | ASR abstraction (Vosk + Dummy) |
| `voice/tts_interface.py` | TTS abstraction (Piper + Dummy) |
| `voice/voice_pipeline.py` | End-to-end voice translation loop |
| `voice/test_microphone.py` | Microphone diagnostic script |
| `benchmarks/benchmark_translation.py` | Translation latency benchmark |
| `benchmarks/benchmark_optimization.py` | Model optimization experiments |
| `data/classroom_test_set.json` | 50 classroom test sentences |
| `data/verified_phrase_bank.json` | Fuzzy matching phrase cache |

## 5. API

```python
from translation.translator import Translator

translator = Translator(phrase_bank_path="data/verified_phrase_bank.json")

result = translator.translate(
    text="बच्चों, इन फलों को गिनो।",
    source="hin_Deva",
    target="sat_Olck",
    context=None  # Optional
)
# result is a dict with: source_text, translated_text, source_language,
# target_language, translation_source, latency_ms, success, error
```

## 6. Model

`ai4bharat/indictrans2-indic-indic-dist-320M`

## 7. Language Codes

- Hindi: `hin_Deva`
- Santali: `sat_Olck`

## 8. Current Performance

### Translation Baseline (50 sentences, CUDA)
| Metric | Value |
|--------|-------|
| Average | 870.76 ms |
| P50 | 645.00 ms |
| P95 | 950.35 ms |
| P99 | 7,290.09 ms |
| Cold start / Max | ~13,248 ms |

### Optimization Benchmark (5 sentences)
| Backend | Avg (ms) | P50 (ms) | RAM (MB) |
|---------|----------|----------|----------|
| PyTorch FP32 (CUDA) | 839.42 | 794.13 | 1,353 |
| PyTorch INT8 (CPU) | 1,507.69 | 1,593.35 | 2,857 |
| CTranslate2 | TBD (not installed) | — | — |
| ONNX | TBD (not installed) | — | — |

## 9. Current Quality

- BLEU: TBD (needs formal reference dataset)
- chrF: TBD
- Human validation: In progress via `verified_phrase_bank.json`
- INT8 quality: 4/5 EXACT MATCH, 1/5 DIFFERS vs FP32

## 10. Known Problems

1. WSL2 does not pass through Windows microphone by default (0 input devices detected).
2. Santali TTS voice does not exist (Piper has no Santali model).
3. Santali ASR model availability is limited.
4. INT8 on CPU is slower than FP32 on CUDA (expected for CPU-only).
5. CTranslate2 and ONNX packages not yet installed in the conda environment.
6. Cold-start latency (~13s) is caused by model/GPU buffer initialization.

## 11. Decisions Made

| Decision | Reason |
|----------|--------|
| Model loaded once in `__init__` | Reloading 1.28 GB per request destroys real-time perf |
| Energy-based VAD (not WebRTC) | Simpler, no extra dependency, sufficient for prototype |
| Threaded mic capture | Prevents audio drops during translation/TTS |
| Vosk as dev ASR backend | Offline, lightweight, Hindi model available |
| Phrase bank with 0.95 threshold | Prevents incorrect fuzzy matches |

## 12. Decisions NOT to Make

- Do NOT put the current PyTorch model directly into Android. M4 must optimize.
- Do NOT use cloud translation/ASR/TTS APIs.
- Do NOT assume INT8 quality is acceptable without native speaker validation.

## 13. Handover to M4

M4 receives:
- Working `translator.py` with stable API
- `benchmark_optimization.py` script (ready to re-run with CT2/ONNX installed)
- Measured baseline numbers
- Voice pipeline architecture that decouples ASR/Translation/TTS

M4 must:
- Install `ctranslate2` and `optimum[onnxruntime]`, re-run benchmarks
- Benchmark on actual ARM64 Android hardware
- Package model + tokenizer for offline deployment
- Optimize for <500 MB RAM

## 14. Handover to M1

M1 calls `translator.translate(text, source, target)` asynchronously from Flutter. Check `result["success"]` before using `result["translated_text"]`. The voice pipeline can run as a background service.

## 15. Handover to M3

M3 can batch-translate curriculum content using `translator.translate()` and store results in the phrase bank for instant retrieval.

## 16. Next Tasks

- [x] Hindi → Santali translation
- [x] Santali → Hindi translation
- [x] Classroom dataset (50 sentences)
- [x] Verified phrase bank
- [x] Fuzzy matching
- [x] Translation benchmark
- [x] Voice pipeline architecture
- [x] Microphone abstraction
- [x] VAD implementation
- [x] ASR interface
- [x] TTS interface
- [x] PyTorch INT8 benchmark
- [ ] Fix WSL microphone access
- [ ] CTranslate2 benchmark (install package)
- [ ] ONNX benchmark (install package)
- [ ] Quality evaluation (BLEU/chrF)
- [ ] End-to-end voice latency measurement
- [ ] ARM64 benchmark
