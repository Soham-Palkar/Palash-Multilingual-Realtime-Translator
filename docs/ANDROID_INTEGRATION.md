# PALASH M2 — Android Application Integration Architecture & Developer Guide

This document provides complete technical documentation for integrating the PALASH M2 voice translation engine into the real Flutter / Android application.

---

## 1. System Architecture Overview

```
-------------------------------------------------------------------------------------
                                FLUTTER UI LAYER
-------------------------------------------------------------------------------------
   Teacher UI (PIN Protected)                  Student UI (Interactive Modules)
   - Real-time Mic Controller                  - Flashcards & Activities
   - Live Transcript & Latency Display         - Audio Playback Receiver
-------------------------------------------------------------------------------------
                                        │
                                        ▼
-------------------------------------------------------------------------------------
                        DART PLATFORM CHANNEL / API CONTRACT
                        (VoiceTranslationService Interface)
-------------------------------------------------------------------------------------
                                        │
                                        ▼
-------------------------------------------------------------------------------------
                             NATIVE ANDROID KOTLIN BRIDGE
                              (VoiceTranslationPlugin.kt)
-------------------------------------------------------------------------------------
         │                              │                             │
         ▼                              ▼                             ▼
-----------------------      -----------------------       --------------------------
   AudioRecord (Mic)            ModelManager (Storage)        AudioTrack (Speaker)
   16 kHz Mono PCM16            Offline Checksums             PCM16 Output Buffer
-----------------------      -----------------------       --------------------------
                                        │
                                        ▼
-------------------------------------------------------------------------------------
                         NATIVE OFFLINE INFERENCE ENGINES
                         (ONNX Runtime / ExecuTorch / NCNN)
-------------------------------------------------------------------------------------
    Hindi ASR Engine    │   IndicTrans2 Engine    │   Santali / Hindi TTS Engine
  (IndicConformer CTC)  │  (Seq2Seq CTranslate2)  │    (DhVaani / Parler-TTS)
-------------------------------------------------------------------------------------
```

---

## 2. Dart API Interface Contract (`VoiceTranslationService`)

The Flutter application consumes the voice translation engine via a platform-neutral API abstraction:

```dart
abstract class VoiceTranslationService {

  /// Initialize engine components and check local model availability.
  Future<void> initialize();

  /// Set or switch translation direction.
  /// Supported:
  ///   - source: "hin_Deva", target: "sat_Olck" (Teacher Mode)
  ///   - source: "sat_Olck", target: "hin_Deva" (Student Mode — Capability Gated)
  Future<void> setDirection(
    String sourceLanguage,
    String targetLanguage,
  );

  /// Start background microphone audio capture and VAD processing.
  Future<void> startListening();

  /// Stop microphone listening and release audio resources.
  Future<void> stopListening();

  /// Stream of partial/interim ASR transcripts.
  Stream<String> get partialTranscript;

  /// Stream of finalized ASR transcripts.
  Stream<String> get finalTranscript;

  /// Stream of target translated text outputs.
  Stream<String> get translation;

  /// Stream of machine-readable engine status events.
  Stream<VoiceStatus> get status;

  /// Stream of high-resolution performance metrics.
  Stream<LatencyMetrics> get latencyMetrics;

  /// Release native memory resources.
  Future<void> dispose();
}

/// Machine-readable engine status.
enum VoiceStatus {
  idle,
  listening,
  speechDetected,
  processing,
  speaking,
  error,
}

/// High-resolution latency payload.
class LatencyMetrics {
  final double asrMs;
  final double translationMs;
  final double ttsMs;
  final double speechEndToPlaybackStartMs;
  final double totalEndToEndMs;

  LatencyMetrics({
    required this.asrMs,
    required this.translationMs,
    required this.ttsMs,
    required this.speechEndToPlaybackStartMs,
    required this.totalEndToEndMs,
  });
}
```

---

## 3. Native Android Kotlin Bridge (`VoiceTranslationPlugin.kt`)

The Flutter app communicates with native Android components via a `MethodChannel` and `EventChannel`:

```kotlin
package com.palash.translator

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class VoiceTranslationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "org.palash/voice_translation")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val ready = ModelManager.verifyModelsExist()
                if (ready) {
                    result.success(mapOf("status" to "READY", "offlineMode" to true))
                } else {
                    result.error("MODEL_MISSING", "Required offline models missing", null)
                }
            }
            "setDirection" -> {
                val source = call.argument<String>("sourceLanguage")
                val target = call.argument<String>("targetLanguage")
                if (source == "sat_Olck") {
                    result.error("ASR_UNAVAILABLE", "Santali ASR pending model integration", null)
                } else {
                    result.success(true)
                }
            }
            "startListening" -> {
                AudioCaptureEngine.start()
                result.success(true)
            }
            "stopListening" -> {
                AudioCaptureEngine.stop()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
```

---

## 4. Audio Input & Output Pipeline

- **Microphone Input**: Android `AudioRecord` configured for `16000 Hz`, `ChannelIn.MONO`, `Encoding.PCM_16BIT`.
- **VAD Processing**: Energy + Preroll (200–300 ms) buffer segmentation running on a dedicated Android background thread.
- **Audio Output**: Android `AudioTrack` configured for `16000 Hz`, `ChannelOut.MONO`, `Encoding.PCM_16BIT` streaming playback.

---

## 5. Teacher vs. Student Role Strategy

### Teacher Device (AI Processing Hub)
- **Permissions**: Microphone, Storage.
- **Access Control**: Protected behind PIN verification.
- **Model Storage**: Downloads and caches heavy AI models locally during first-time setup (~3.5 GB).
- **Execution**: Runs ASR, IndicTrans2, and TTS locally offline.

### Student Device (Lightweight Client)
- **Model Storage**: **NO AI models downloaded**. Lightweight app size (< 50 MB).
- **Functionality**: Classroom interactive modules, flashcards, worksheets, and receiving audio broadcast from Teacher device over local Wi-Fi/Hotspot.

---

## 6. Machine-Readable Error Contract

The native engine exposes the following standardized error codes to Flutter UI:

| Error Code | Description | UI Action |
|---|---|---|
| `MODEL_MISSING` | Required offline model files are missing from app storage. | Prompt setup screen. |
| `MODEL_LOAD_FAILED` | Out of memory or corrupted model weights. | Suggest clearing cache or restarting. |
| `MICROPHONE_PERMISSION_DENIED` | Android mic permission not granted. | Open system permissions settings. |
| `MICROPHONE_ERROR` | AudioRecord initialization failure. | Prompt device restart. |
| `ASR_UNAVAILABLE` | Santali ASR requested before model availability. | Block direction switch with UI note. |
| `TRANSLATION_FAILED` | Invalid text or model generation error. | Log warning, reset utterance. |
| `TTS_UNAVAILABLE` | Target TTS engine failed to load. | Fall back to text display. |
| `TTS_FAILED` | Synthesis error for current text. | Reset utterance and keep listening. |

---

## 7. Model Storage & Offline Verification

Models must be stored in the app-private internal directory:
`/data/user/0/org.palash.translator/files/models/`

Directory Layout:
```
models/
├── asr_hi/
│   ├── model.onnx (or .nemo)
│   └── tokenizer.model
├── translation/
│   ├── model.bin (CTranslate2 / IndicTrans2)
│   └── source.spm
└── tts_sat/
    ├── model.safetensors (DhVaani / Parler-TTS)
    └── config.json
```

Each model file must undergo SHA256 checksum verification before activation to guarantee data integrity.
