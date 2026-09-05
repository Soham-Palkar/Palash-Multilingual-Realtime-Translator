import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/translation_model.dart';
import '../../../services/translation_service.dart';
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
  TranslationResult? _currentResult;
  bool _isTranslating = false;
  bool _isListening = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
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

  Future<void> _handleVoiceTranslate() async {
    setState(() => _isListening = true);

    // Simulate speech recording phase
    await Future.delayed(const Duration(milliseconds: 1600));

    final transSvc = Provider.of<TranslationService>(context, listen: false);
    final voiceRes = await transSvc.translateVoice(_inputController.text.trim());

    if (mounted) {
      setState(() {
        _isListening = false;
        _inputController.text = voiceRes.transcribedHindi;
        _currentResult = TranslationResult(
          sourceText: voiceRes.transcribedHindi,
          translatedSantali: voiceRes.translatedSantali,
          translatedOlChiki: voiceRes.translatedOlChiki,
          phoneticRoman: voiceRes.phoneticRoman,
          confidence: voiceRes.confidence,
        );
      });
    }
  }

  void _handleClear() {
    setState(() {
      _inputController.clear();
      _currentResult = null;
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
                      if (_inputController.text.isNotEmpty)
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
                      hintText: 'शिक्षक का हिन्दी वाक्य लिखें या बोलें...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Voice Speaking Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isListening || _isTranslating ? null : _handleVoiceTranslate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isListening ? AppColors.error : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _isListening ? 'रिकॉर्डिंग हो रही है...' : 'बोलकर अनुवाद करें',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Text Translate Button
                      IconButton.filled(
                        onPressed: _isTranslating || _isListening ? null : _handleTextTranslate,
                        icon: _isTranslating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱚᱨᱡᱚᱢᱟ (Santali Output)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
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
