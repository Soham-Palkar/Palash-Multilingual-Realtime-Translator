# PALASH Android Optimization Report

## Owner
M2 (research & benchmarking) → M4 (final deployment)

## Baseline

| Property | Value |
|----------|-------|
| Model | `ai4bharat/indictrans2-indic-indic-dist-320M` |
| Runtime | PyTorch FP32 |
| Device | CUDA (development) / CPU |
| Avg latency (50 sentences) | 870.76 ms |
| P50 | 645.00 ms |
| P95 | 950.35 ms |
| Model disk size | ~1.28 GB |

## Optimization Experiments

### Summary Table (Measured)

| Backend | Status | Avg (ms) | P50 (ms) | RAM (MB) |
|---------|--------|----------|----------|----------|
| PyTorch FP32 (CUDA) | ✅ OK | 839.42 | 794.13 | 1,353 |
| PyTorch INT8 (CPU) | ✅ OK | 1,507.69 | 1,593.35 | 2,857 |
| CTranslate2 FP32 | ❌ FAILED | N/A | N/A | N/A |
| ONNX FP32 | ❌ FAILED | N/A | N/A | N/A |

### 1. PyTorch FP32 (Baseline)
- **Status**: ✅ Working
- **RAM**: 1,353 MB (process RSS after model load)
- **Avg latency**: 839.42 ms (5 runs, 5 sentences)
- **P50**: 794.13 ms
- **Quality**: Reference baseline — all outputs are correct

### 2. PyTorch Dynamic INT8 (CPU)
- **Status**: ✅ Working, but **slower** and **higher RAM** than FP32 on CUDA
- **RAM**: 2,857 MB
- **Avg latency**: 1,507.69 ms (CPU-only, no GPU acceleration)
- **P50**: 1,593.35 ms
- **Quality**: 4/5 sentences were EXACT MATCH. 1/5 DIFFERS (sentence 0: "बच्चों, इन फलों को गिनो।" produced a different Santali output).
- **Conclusion**: INT8 dynamic quantization on CPU is **slower** than FP32 on CUDA. However, this is the CPU-only comparison. On ARM64 Android (where CUDA is unavailable), INT8 may still be the best option for reducing model size. Needs ARM64 benchmark.

### 3. CTranslate2
- **Status**: ❌ FAILED — `ctranslate2` package not installed in environment
- **Action for M4**: Install `ctranslate2` and re-run `benchmark_optimization.py`. This is the most promising candidate for Android CPU deployment due to its efficient C++ runtime and INT8 support.

### 4. ONNX Runtime
- **Status**: ❌ FAILED — `optimum[onnxruntime]` package not installed in environment
- **Action for M4**: Install `pip install optimum[onnxruntime]` and re-run. ONNX export may also fail due to custom model architecture in IndicTrans2.

## Quality Comparison (Measured)

5 test sentences were translated by each backend and compared to PyTorch FP32:

| Sentence | PyTorch FP32 → INT8 |
|----------|---------------------|
| बच्चों, इन फलों को गिनो। | **DIFFERS** |
| अपनी किताब खोलो। | EXACT MATCH |
| बैठ जाओ। | EXACT MATCH |
| ध्यान से सुनो। | EXACT MATCH |
| अपना नाम बताओ। | EXACT MATCH |

> The INT8 divergence on sentence 0 shows that quantization can alter translations. Native speaker validation is required before accepting INT8 outputs.

## ARM64 Results

No ARM64 hardware benchmark has been performed. All results above are from x86_64 (WSL2 / CUDA).

> ⚠️ Do NOT interpret x86 CUDA numbers as Android ARM64 performance.

## Recommendation for M4

1. **CTranslate2 INT8** is the top priority for investigation. Install `ctranslate2`, convert the model, and benchmark on CPU. CTranslate2 is specifically designed for efficient CPU inference and has ARM64 support.
2. **ONNX Runtime Mobile** is a secondary option. Attempt the export; if it fails due to custom architecture, document and move on.
3. **PyTorch INT8** is usable but showed higher RAM (2.8 GB) and slower CPU latency (1.5s). It may still be useful on ARM64 where it's the only available runtime.
4. All optimized backends must be validated against native Santali speakers before deployment.
