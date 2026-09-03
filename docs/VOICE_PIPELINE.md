# PALASH Voice Pipeline

## Owner
M2

## Overview
The voice pipeline provides real-time, hands-free voice translation between a Hindi-speaking teacher and Santali-speaking students.

## Architecture

```
Physical Microphone
        ↓
  Audio Capture (PCM, mono, 16kHz, 16-bit)
        ↓
  Audio Buffer (thread-safe)
        ↓
  Voice Activity Detection (Energy-based)
        ↓
  Offline ASR (Vosk / sherpa-onnx)
        ↓
  M2 Translation Engine (IndicTrans2)
        ↓
  Offline TTS (Piper / future)
        ↓
  Speaker / Amplifier
```

## Modules

### `voice/microphone.py`
- Uses PyAudio to enumerate and select input devices.
- Prefers external USB microphones when available.
- Streams PCM chunks (1024 frames at 16kHz = 64ms per chunk).

### `voice/audio_buffer.py`
- Thread-safe byte buffer for accumulating speech segments.
- Supports append, read, clear, and duration calculation.

### `voice/vad.py`
- Energy-based Voice Activity Detection.
- States: `IDLE` → `SPEECH_DETECTED` → `RECORDING` → `END_OF_SPEECH`.
- Configurable: `energy_threshold`, `min_speech_ms`, `min_silence_ms`.
- Does NOT require Push-to-Talk.

### `voice/asr_interface.py`
- Abstract `ASREngine` interface with `start_stream()`, `accept_audio()`, `get_partial_result()`, `get_final_result()`, `stop_stream()`.
- `VoskASRBackend`: Offline Hindi ASR using Vosk. Requires a downloaded Vosk Hindi model.
- `DummyASRBackend`: Returns fixed Hindi text for pipeline testing.

### `voice/tts_interface.py`
- Abstract `TTSEngine` with `synthesize(text, language)` → PCM bytes.
- `PiperTTSBackend`: Offline TTS using Piper. Hindi voice available. **Santali voice: BLOCKED (no model exists).**
- `DummyTTSBackend`: Returns silence for pipeline testing.

### `voice/voice_pipeline.py`
- Main loop: captures audio on a background thread, processes VAD, runs ASR on speech segments, translates, synthesizes, and plays back.
- Direction switching: `set_direction(source, target)` for teacher/student modes.
- Per-stage latency tracking: `vad_ms`, `asr_ms`, `translation_ms`, `tts_ms`, `total_end_to_end_ms`.

## Data Flow

### Teacher Mode (Hindi → Santali)
```
Teacher speaks Hindi
  → Microphone captures PCM
  → VAD detects speech start/end
  → ASR produces Hindi text
  → Translation API: hin_Deva → sat_Olck
  → TTS synthesizes Santali speech
  → Speaker plays for student
```

### Student Mode (Santali → Hindi)
```
Student speaks Santali
  → Microphone captures PCM
  → VAD detects speech start/end
  → ASR produces Santali text
  → Translation API: sat_Olck → hin_Deva
  → TTS synthesizes Hindi speech
  → Speaker plays for teacher
```

## How to Run

```bash
conda activate palash-translate
cd "AI POC"

# Test microphone detection
python voice/test_microphone.py

# Run the full pipeline (requires microphone access)
python voice/voice_pipeline.py --source hin_Deva --target sat_Olck --energy 500
```

## Latency Measurement

Each pipeline run records:
```json
{
    "vad_ms": 0.05,
    "asr_ms": 150,
    "translation_ms": 645,
    "tts_ms": 200,
    "total_end_to_end_ms": 1200
}
```

Target: ≤ 3 seconds end-to-end for normal classroom utterances.

## WSL Audio Status

**BLOCKED**: WSL2 does not pass through Windows microphone hardware by default. The diagnostic script (`voice/test_microphone.py`) reported 0 input devices. Required fixes:
1. Set `PULSE_SERVER=/mnt/wslg/PulseServer` (WSLg on Windows 11).
2. Or install a Windows PulseAudio server and configure TCP forwarding.

## Known Limitations

- Real microphone requires WSL audio configuration or native Linux/Windows execution.
- Santali TTS voice does not exist yet (BLOCKED).
- Santali ASR model availability is limited.
- VAD energy threshold needs tuning per environment.
