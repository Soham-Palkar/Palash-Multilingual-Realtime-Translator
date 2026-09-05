# PALASH M2 — Execution & Execution Run Guide

This guide describes how to run unit tests, execute latency benchmarks, and launch the real-time offline physical microphone voice translation system on Windows + WSL.

---

## 1. Quick Verification Commands

### Step 1: Verify CUDA in WSL Environment
```bash
wsl.exe /home/soham_palkar/miniconda3/envs/palash-translate/bin/python -c "import torch; print('CUDA Available:', torch.cuda.is_available()); print('Device:', torch.cuda.get_device_name(0))"
```

### Step 2: Verify Offline Model Availability
```bash
wsl.exe /home/soham_palkar/miniconda3/envs/palash-translate/bin/python -c "from voice.model_manager import ModelManager; ModelManager().check_offline_readiness()"
```

---

## 2. Unit Test Suite Execution

Run the complete 17-test unit suite across ASR, Translation, TTS, VAD, and ModelManager:

```bash
# Run in WSL environment
wsl.exe /home/soham_palkar/miniconda3/envs/palash-translate/bin/python -m unittest discover -s "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/Palash-Multilingual-Realtime-Translator/AI POC/tests" -p "test_*.py"
```

---

## 3. Latency Benchmarking

To measure empirical sub-stage latencies (ASR, Translation, TTS, Time-to-Playback-Start):

```bash
# Run in WSL CUDA environment
wsl.exe /home/soham_palkar/miniconda3/envs/palash-translate/bin/python "/mnt/c/Users/Soham Palkar/OneDrive/Desktop/Palash-Multilingual-Realtime-Translator/AI POC/benchmarks/benchmark_voice_pipeline.py"
```

Results will be displayed in stdout and written to `AI POC/benchmarks/benchmark_results.json`.

---

## 4. Real Physical Microphone Translation Pipeline

Launch the interactive voice translation pipeline with real-time physical microphone capture on Windows host and CUDA AI inference worker in WSL:

```powershell
# Run from Windows PowerShell / Command Prompt
python "AI POC/voice/realtime_translation.py"
```

Flow during execution:
1. Physical Microphone captures speech on Windows host.
2. VAD detects speech end and passes PCM16 audio over persistent JSON IPC to WSL worker.
3. IndicConformer Hindi ASR transcribes text.
4. IndicTrans2 translates Hindi to Santali (`sat_Olck`).
5. Indic Parler-TTS / DhVaani synthesizes Santali audio.
6. AudioOutput plays synthesized audio on Windows host speaker.
