# PALASH AI Model Evaluation & Benchmark Comparison

This document maintains empirical evaluation metrics, hardware footprints, latency stats, and deployment feasibility for all ASR, Translation, and TTS models tested in the PALASH project.

---

## 1. Comprehensive Model Comparison Matrix

| Component | Model Name | Languages | Size (MB / GB) | License | Audio Quality | Warm Latency | RAM / VRAM | Offline Mode | Android Feasibility | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| **Hindi ASR** | `ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large` | Hindi (`hin_Deva`) | ~2.2 GB | MIT / Open | High | **125.06 ms** | ~2.5 GB VRAM | **YES** | High (ONNX / TFLite compatible) | **PASS (Production Ready)** |
| **Santali ASR** | *Awaiting official NeMo model* | Santali (`sat_Olck`) | TBD | TBD | TBD | TBD | TBD | **YES** | TBD | **PENDING MODEL INTEGRATION** |
| **Translation Engine** | `ai4bharat/indictrans2-indic-indic-dist-320M` | `hin_Deva` ↔ `sat_Olck` | ~1.2 GB | MIT | High | **426.5 ms** (greedy `num_beams=1`) | ~1.5 GB VRAM | **YES** | High (CTranslate2 / ONNX ready) | **PASS (Production Ready)** |
| **Santali TTS (Reference)** | `ai4bharat/indic-parler-tts` (Arjun voice) | Santali (`sat_Olck`) | ~3.75 GB (FP32) / ~1.8 GB (BF16) | MIT | Very High | **13.75 s** | ~4.0 GB VRAM | **YES** | Low (Heavy transformer decoder) | **REJECTED FOR SUB-5S LATENCY (REFERENCE QUALITY BASELINE)** |
| **Santali TTS (Candidate)** | `DhVaani / ZipVoice` | Multilingual (27 Indian) | ~491 MB | Open Source | Medium-High | **1.2 – 2.5 s** | ~1.0 GB VRAM | **YES** | High (< 500 MB footprint, mobile friendly) | **EVALUATED / CANDIDATE FOR MOBILE RUNTIME** |

---

## 2. Benchmark Summary & Latency Profile

### ASR + Translation Acceleration
By introducing `torch.inference_mode()`, greedy decoding (`num_beams=1`), and persistent CUDA loading, the frontend latency of speech processing was dramatically reduced:
- **ASR Latency**: $125.06\text{ ms}$
- **Translation Latency**: $426.50\text{ ms}$
- **Combined ASR + Translation**: $< 600\text{ ms}$ ($0.55\text{ s}$)

### Parler-TTS Latency Analysis & Rejection Rationale
While AI4Bharat Indic Parler-TTS produces crystal-clear Santali speech with the Arjun voice, its autoregressive architecture generates audio tokens sequentially. Even with BF16 precision and `torch.inference_mode()`, warming synthesis takes **13.75 seconds**, missing the $\le 4\text{–}5\text{ second}$ target.
- **Decision**: Retain Parler-TTS in `indic_parler_tts.py` as the reference quality baseline.
- **Alternative**: DhVaani (ZipVoice architecture, 491 MB) runs in **1.2–2.5 s**, satisfying the $\le 4\text{–}5\text{ s}$ speech-end to playback start target for mobile/Android deployments.

---

## 3. Offline Verification

All primary models are verified for **100% offline operation** once cached locally:
- `ASR_HINDI`: Local NeMo checkpoint verified (`~/.cache/huggingface/hub/models--ai4bharat--indicconformer_stt_hi_hybrid_rnnt_large`)
- `TRANSLATOR`: Local PyTorch safetensors verified (`~/.cache/huggingface/hub/models--ai4bharat--indictrans2-indic-indic-dist-320M`)
- `TTS_SANTALI`: Local model files verified (`~/.cache/huggingface/hub/models--ai4bharat--indic-parler-tts`)
- `OFFLINE_MODE`: Enabled (`INTERNET = OFF`)
