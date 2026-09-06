import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/translation_model.dart';
import '../../../services/translation_service.dart';
import '../../../database/app_database.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/palash_card.dart';

class LiveTranslationScreen extends StatefulWidget {
  const LiveTranslationScreen({super.key});

  @override
  State<LiveTranslationScreen> createState() => _LiveTranslationScreenState();
}

class _LiveTranslationScreenState extends State<LiveTranslationScreen> {
  final _inputController = TextEditingController(text: 'आज हम सब मिलकर गणित का नया पाठ सीखेंगे');
  final AudioRecorder _audioRecorder = AudioRecorder();

  TranslationResult? _currentResult;
  bool _isTranslating = false;
  bool _isRecording = false;
  bool _isSaving = false;
  String? _recordedAudioPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // STOP RECORDING
      try {
        final path = await _audioRecorder.stop();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordedAudioPath = path;
          });
          if (path != null && path.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.secondary,
                content: Text('रिकॉर्डिंग समाप्त हुई। भेजने के लिए "भेजें / Send" बटन दबाएं।'),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isRecording = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.error, content: Text('रिकॉर्डिंग रोकने में त्रुटि: $e')),
          );
        }
      }
    } else {
      // START RECORDING
      try {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.error,
                content: Text('ऑडियो रिकॉर्ड करने के लिए माइक्रोफ़ोन अनुमति आवश्यक है। / Microphone permission is required to record audio.'),
              ),
            );
          }
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final path = p.join(
          tempDir.path,
          'translation_rec_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        await _audioRecorder.start(
          const RecordConfig(),
          path: path,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _recordedAudioPath = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isRecording = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.error, content: Text('रिकॉर्डिंग शुरू करने में त्रुटि: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleSendRecording() async {
    if (_recordedAudioPath == null || _recordedAudioPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('कोई रिकॉर्डिंग उपलब्ध नहीं है। कृपया पहले बोलकर रिकॉर्ड करें। / No recording available.'),
        ),
      );
      return;
    }

    final file = File(_recordedAudioPath!);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('ऑडियो फ़ाइल नहीं मिली। / Recording file not found.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid ?? 'teacher';
      final recording = TranslationRecording(
        id: 'rec_${const Uuid().v4().substring(0, 8)}',
        audioPath: _recordedAudioPath!,
        teacherId: teacherId,
      );

      await AppDatabase.instance.insertTranslationRecording(recording);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _recordedAudioPath = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text('रिकॉर्डिंग सफलतापूर्वक सहेजी गई! / Recording saved successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('सहेजने में त्रुटि: $e'),
          ),
        );
      }
    }
  }

  Future<void> _handleTextTranslate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isTranslating = true);
    final transSvc = Provider.of<TranslationService>(context, listen: false);

    try {
      final res = await transSvc.translateText(text);
      if (mounted) {
        setState(() {
          _currentResult = res;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('त्रुटि: $e')),
        );
      }
    }
  }

  void _handleClear() {
    setState(() {
      _inputController.clear();
      _currentResult = null;
      _recordedAudioPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final transSvc = Provider.of<TranslationService>(context);
    final history = transSvc.getSessionHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.g_translate_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'लाइव अनुवाद स्टूडियो',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Internet Connection Prototype Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.liveTranslationNotice,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF01579B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Hindi Input Card
            PalashCard(
              elevation: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'हिन्दी इनपुट (Hindi Input)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (_inputController.text.isNotEmpty || _recordedAudioPath != null)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: _handleClear,
                          tooltip: 'हटाएं (Clear)',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'शिक्षक का हिन्दी वाक्य लिखें या बोलकर रिकॉर्ड करें...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Voice Recording Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving || _isTranslating ? null : _toggleRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? AppColors.error : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _isRecording
                                ? '⏹ रोकें (Stop)'
                                : (_recordedAudioPath != null ? '🎙 नई रिकॉर्डिंग' : '🎙 रिकॉर्ड करें (Record)'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send Recording Button
                      ElevatedButton.icon(
                        onPressed: (_recordedAudioPath != null && !_isRecording && !_isSaving)
                            ? _handleSendRecording
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isSaving ? 'सहेज रहे...' : 'भेजें (Send)',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text Translate Button
                      IconButton.filled(
                        onPressed: _isTranslating || _isRecording || _isSaving ? null : _handleTextTranslate,
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.g_translate_rounded, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.moduleLanguage,
                        ),
                        tooltip: 'पाठ्य अनुवाद करें (Translate Text)',
                      ),
                    ],
                  ),
                  if (_recordedAudioPath != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.audiotrack_rounded, color: AppColors.secondary, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ऑडियो रिकॉर्डिंग तैयार है (Recording Ready to Send)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Translation Output Display
            if (_currentResult != null) ...[
              PalashCard(
                backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                borderColor: AppColors.secondary.withOpacity(0.3),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱚᱨᱡᱚᱢᱟ (Santali Output)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Confidence: ${(_currentResult!.confidence * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _currentResult!.translatedSantali,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    if (_currentResult!.translatedOlChiki != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ᱚᱞ ᱪᱤᱠᱤ: ${_currentResult!.translatedOlChiki}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                    if (_currentResult!.phoneticRoman != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phonetic: ${_currentResult!.phoneticRoman}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Current Session Translation History
            if (history.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'सत्र अनुवाद इतिहास (${history.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      transSvc.clearHistory();
                      setState(() {});
                    },
                    child: const Text('इतिहास साफ करें'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PalashCard(
                      padding: const EdgeInsets.all(14),
                      child: BilingualText(
                        hindi: item.sourceText,
                        santali: item.translatedSantali,
                        santaliOlChiki: item.translatedOlChiki,
                        hindiFontSize: 14,
                        santaliFontSize: 13,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
