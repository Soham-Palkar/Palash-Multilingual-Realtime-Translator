import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/translation_model.dart';
import '../../../services/translation_service.dart';
import '../../../services/text_to_speech_service.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/palash_card.dart';

class LiveTranslationScreen extends StatefulWidget {
  const LiveTranslationScreen({super.key});

  @override
  State<LiveTranslationScreen> createState() => _LiveTranslationScreenState();
}

class _LiveTranslationScreenState extends State<LiveTranslationScreen> {
  final _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Session State
  bool _isSessionActive = false; // Main interpretation session toggle
  bool _isSpeechAvailable = false;
  bool _isTranslating = false;

  // Transcript Buffers
  String _accumulatedText = ''; // Text from finished listening segments
  String _currentSegmentText = ''; // Text from active listening segment
  int _processedCharCount = 0; // Pointer for simultanous translation

  // Constants
  static const Duration _silenceThreshold = Duration(seconds: 5);
  Timer? _silenceTimer;

  // UI State History
  final List<TranslationResult> _translationHistory = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onError: (val) => _onInternalSpeechError(val),
        onStatus: (val) => _onInternalSpeechStatus(val),
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Speech engine initialization error: $e');
    }
  }

  /// Internal handler for STT engine status changes.
  /// Used to ensure the microphone stays active even if the plugin stops.
  void _onInternalSpeechStatus(String status) {
    debugPrint('STT Engine Status: $status');
    if (status == 'done' || status == 'notListening') {
      if (_isSessionActive && mounted) {
        _restartListeningSegment();
      }
    }
  }

  void _onInternalSpeechError(dynamic error) {
    debugPrint('STT Engine Error: $error');
    if (_isSessionActive && mounted) {
      _restartListeningSegment();
    }
  }

  /// Restarts the microphone while keeping the overall session active.
  void _restartListeningSegment() {
    setState(() {
      _accumulatedText = '$_accumulatedText $_currentSegmentText'.trim();
      _currentSegmentText = '';
    });
    // Brief cooldown to avoid immediate re-trigger errors
    Future.delayed(const Duration(milliseconds: 200), () {
      _startMicrophone();
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  /// Main Session Start/Stop Toggle
  Future<void> _toggleLiveSession() async {
    if (_isSessionActive) {
      // STOP SESSION
      setState(() => _isSessionActive = false);
      _silenceTimer?.cancel();
      await _speech.stop();

      // Finalize any remaining text immediately
      _finalizeCurrentChunk();
    } else {
      // START SESSION
      if (!_isSpeechAvailable) {
        _showToast('स्पीच रिकग्निशन उपलब्ध नहीं है।');
        return;
      }

      final hasPermission = await _speech.hasPermission;
      if (!hasPermission) {
        _showToast('माइक्रोफ़ोन अनुमति आवश्यक है।');
        return;
      }

      setState(() {
        _isSessionActive = true;
        _accumulatedText = '';
        _currentSegmentText = '';
        _processedCharCount = 0;
        _translationHistory.clear();
      });

      _startMicrophone();
    }
  }

  Future<void> _startMicrophone() async {
    if (!mounted || !_isSessionActive || _speech.isListening) return;

    try {
      await _speech.listen(
        onResult: _onSpeechUpdate,
        localeId: 'hi_IN',
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation, // Dictation for long-form speech
        partialResults: true,
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
    }
  }

  void _onSpeechUpdate(SpeechRecognitionResult result) {
    // 1. Update Current Text
    setState(() {
      _currentSegmentText = result.recognizedWords;
    });

    // 2. Reset Silence Timer
    _silenceTimer?.cancel();
    if (_isSessionActive) {
      _silenceTimer = Timer(_silenceThreshold, () {
        _finalizeCurrentChunk();
      });
    }
  }

  String get _fullTranscript => '$_accumulatedText $_currentSegmentText'.trim();

  /// Finalizes the current speech chunk when 5 seconds of silence is detected.
  void _finalizeCurrentChunk() {
    final full = _fullTranscript;
    if (full.length <= _processedCharCount) return;

    // Extract only the new chunk since the last finalization
    String newChunk = full.substring(_processedCharCount).trim();

    // Ignore tiny noises
    if (newChunk.length < 3) return;

    _processedCharCount = full.length;
    debugPrint('Finalizing Interpretation Chunk: $newChunk');

    _translateAndPlay(newChunk);
  }

  /// Sends the finalized Hindi chunk for translation and sequential audio playback.
  Future<void> _translateAndPlay(String text) async {
    setState(() => _isTranslating = true);

    final transSvc = Provider.of<TranslationService>(context, listen: false);
    final ttsSvc = Provider.of<TextToSpeechService>(context, listen: false);

    try {
      final result = await transSvc.translateText(text);
      if (mounted) {
        setState(() {
          _translationHistory.insert(0, result);
          _isTranslating = false;
        });

        // Automated TTS playback (sequential queue handled inside service)
        ttsSvc.speakSantali(result.translatedSantali);

        // Auto-scroll to top of stream
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _handleClearAll() {
    Provider.of<TextToSpeechService>(context, listen: false).stop();
    setState(() {
      _translationHistory.clear();
      _accumulatedText = '';
      _currentSegmentText = '';
      _processedCharCount = 0;
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: AppColors.error, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.g_translate_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'निरंतर अनुवाद (Simultaneous)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _handleClearAll,
            tooltip: 'सत्र साफ करें',
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionStatusIndicator(),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(18),
              children: [
                _buildLiveInputCard(),
                const SizedBox(height: 24),
                if (_translationHistory.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'अनुवाद प्रवाह (Interpretation Stream)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ..._translationHistory.map((item) => _buildStreamItem(item)),
                ],
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _toggleLiveSession,
        backgroundColor: _isSessionActive ? AppColors.error : AppColors.primary,
        child: Icon(
          _isSessionActive ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSessionStatusIndicator() {
    String statusLabel = 'तैयार (Ready)';
    Color statusColor = AppColors.info;

    if (_isSessionActive) {
      statusLabel = 'सुन रहे हैं... (Listening Simulatneously)';
      statusColor = Colors.green;
    }
    if (_isTranslating) {
      statusLabel = 'अनुवाद हो रहा है... (Translating...)';
      statusColor = AppColors.moduleLanguage;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: statusColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveInputCard() {
    final displayTranscript = _fullTranscript;
    return PalashCard(
      elevation: 2,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Text('शिक्षक की आवाज (Live Hindi Stream)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (_isSessionActive)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayTranscript.isEmpty
              ? (_isSessionActive ? 'बोलना शुरू करें...' : 'शुरू करने के लिए माइक दबाएं')
              : displayTranscript,
            style: TextStyle(
              fontSize: 16,
              color: displayTranscript.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
              fontStyle: displayTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamItem(TranslationResult item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PalashCard(
        backgroundColor: AppColors.secondaryContainer.withOpacity(0.3),
        borderColor: AppColors.secondary.withOpacity(0.2),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.sourceText,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.volume_up_rounded, size: 18, color: AppColors.secondary),
                  onPressed: () => Provider.of<TextToSpeechService>(context, listen: false).speakSantali(item.translatedSantali),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              item.translatedSantali,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
