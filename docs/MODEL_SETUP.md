# PALASH Model Download, Environment Setup & Offline Verification Guide

This guide details the exact steps and commands to set up the execution environment, download required AI model weights, verify offline availability, and configure Hugging Face caching for Windows and WSL.

---

## 1. Environment Setup

### Windows Host Environment (Audio IO & CLI Client)
```powershell
# Create & activate Python virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install Windows requirements
pip install pyaudio numpy soundfile torch transformers
```

### WSL Ubuntu Environment (CUDA AI Inference Worker)
```bash
# Open WSL terminal
wsl.exe

# Activate conda environment
conda activate palash-translate

# Verify CUDA acceleration
python -c "import torch; print('CUDA Available:', torch.cuda.is_available()); print('Device:', torch.cuda.get_device_name(0))"
```

---

## 2. Hugging Face Authentication & Model Downloading

Models are downloaded once during setup from Hugging Face Hub:
1. `ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large` (Hindi ASR)
2. `ai4bharat/indictrans2-indic-indic-dist-320M` (Translation)
3. `ai4bharat/indic-parler-tts` (Santali / Hindi TTS Baseline)

### Downloading Models via Python Script (Run in WSL)
```python
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from parler_tts import ParlerTTSForConditionalGeneration
import nemo.collections.asr as nemo_asr

print("1. Downloading Hindi ASR model...")
nemo_asr.models.ASRModel.from_pretrained("ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large")

print("2. Downloading IndicTrans2 Translation model...")
AutoTokenizer.from_pretrained("ai4bharat/indictrans2-indic-indic-dist-320M", trust_remote_code=True)
AutoModelForSeq2SeqLM.from_pretrained("ai4bharat/indictrans2-indic-indic-dist-320M", trust_remote_code=True)

print("3. Downloading Indic Parler-TTS model...")
AutoTokenizer.from_pretrained("ai4bharat/indic-parler-tts")
ParlerTTSForConditionalGeneration.from_pretrained("ai4bharat/indic-parler-tts")

print("[SETUP COMPLETE] All models successfully cached.")
```

---

## 3. Local Model Cache Locations

By default, models are cached in the user home directory:
- **WSL Linux Cache**: `/home/<user>/.cache/huggingface/hub/`
  - `models--ai4bharat--indicconformer_stt_hi_hybrid_rnnt_large`
  - `models--ai4bharat--indictrans2-indic-indic-dist-320M`
  - `models--ai4bharat--indic-parler-tts`
- **Windows Host Cache**: `C:\Users\<user>\.cache\huggingface\hub\`

---

## 4. Offline Verification & Runtime Mode

To verify offline operation, disable internet access or test local model presence:

```bash
# Run PALASH ModelManager offline inspection
python -c "from voice.model_manager import ModelManager; manager = ModelManager(); manager.check_offline_readiness()"
```

Expected Output:
```
[OFFLINE CHECK] Inspecting local model availability...
[OFFLINE CHECK] Cache root: /home/soham_palkar/.cache/huggingface
  - ASR_HINDI (ai4bharat/indicconformer_stt_hi_hybrid_rnnt_large): [OFFLINE READY]
  - TRANSLATOR (ai4bharat/indictrans2-indic-indic-dist-320M): [OFFLINE READY]
  - TTS_SANTALI (ai4bharat/indic-parler-tts): [OFFLINE READY]
  - TTS_HINDI (ai4bharat/indic-parler-tts): [OFFLINE READY]
  - ASR_SANTALI (ai4bharat/indicconformer_stt_sat_large): [PENDING MODEL INTEGRATION]
[OFFLINE] Models available locally. Runtime mode enabled.
```
