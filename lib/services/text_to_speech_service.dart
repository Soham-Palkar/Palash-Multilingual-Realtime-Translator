import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for Text-to-Speech functionality.
/// Focuses on Santali language support for the PALASH project.
/// Includes a sequential queue for continuous translation playback.
class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isSantaliSupportedNatively = false;
  bool _isSpeaking = false;
  final List<String> _queue = [];

  TextToSpeechService() {
    _initTts();
    _setupAudioPlayerListeners();
  }

  Future<void> _initTts() async {
    try {
      // Check for Santali support in native engine
      List<dynamic>? languages = await _flutterTts.getLanguages;
      if (languages != null) {
        _isSantaliSupportedNatively = languages.any((lang) =>
            lang.toString().toLowerCase().contains('sat') ||
            lang.toString().toLowerCase().contains('santali'));
      }

      await _flutterTts.setLanguage("hi-IN");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _onSpeechFinished();
      });
    } catch (e) {
      debugPrint("TTS Initialization error: $e");
    }
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _onSpeechFinished();
    });
  }

  void _onSpeechFinished() {
    _isSpeaking = false;
    _processNextInQueue();
  }

  /// Speaks the given text in Santali.
  /// Uses a queue to handle simultaneous translation chunks sequentially.
  Future<void> speakSantali(String text) async {
    if (text.trim().isEmpty) return;
    _queue.add(text);
    if (!_isSpeaking) {
      await _processNextInQueue();
    }
  }

  Future<void> _processNextInQueue() async {
    if (_queue.isEmpty || _isSpeaking) return;

    final text = _queue.removeAt(0);
    _isSpeaking = true;

    if (_isSantaliSupportedNatively) {
      debugPrint("Using native TTS for Santali: $text");
      await _flutterTts.setLanguage("sat-IN");
      await _flutterTts.speak(text);
    } else {
      debugPrint("Santali not supported natively. Falling back to Online TTS: $text");
      await _speakOnline(text, 'sat');
    }
  }

  /// Speaks the given text in Hindi.
  Future<void> speakHindi(String text) async {
    await _flutterTts.setLanguage("hi-IN");
    await _flutterTts.speak(text);
  }

  /// Fallback for languages not supported by native TTS engine.
  Future<void> _speakOnline(String text, String langCode) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = "https://translate.google.com/translate_tts?ie=UTF-8&q=$encodedText&tl=$langCode&client=tw-ob";
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint("Online TTS error: $e");
      _isSpeaking = false;
      _processNextInQueue();
    }
  }

  Future<void> stop() async {
    _queue.clear();
    _isSpeaking = false;
    await _flutterTts.stop();
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
