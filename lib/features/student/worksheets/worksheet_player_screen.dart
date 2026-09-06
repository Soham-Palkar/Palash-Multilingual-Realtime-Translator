import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/worksheet_model.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/feedback_banner.dart';
import '../../../widgets/palash_asset_image.dart';
import '../../../widgets/palash_card.dart';

class WorksheetPlayerScreen extends StatefulWidget {
  final WorksheetItem worksheet;

  const WorksheetPlayerScreen({super.key, required this.worksheet});

  @override
  State<WorksheetPlayerScreen> createState() => _WorksheetPlayerScreenState();
}

class _WorksheetPlayerScreenState extends State<WorksheetPlayerScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasAnswered = false;
  bool _isAnswerCorrect = false;
  int _score = 0;

  void _handleOptionSelect(int index) {
    if (_hasAnswered && _isAnswerCorrect) return;

    final question = widget.worksheet.questions[_currentIndex];
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedOptionIndex = index;
      _hasAnswered = true;
      _isAnswerCorrect = isCorrect;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _handleNextOrRetry() {
    if (_isAnswerCorrect) {
      if (_currentIndex < widget.worksheet.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedOptionIndex = null;
          _hasAnswered = false;
          _isAnswerCorrect = false;
        });
      } else {
        _showCompletionDialog();
      }
    } else {
      // Retry current question
      setState(() {
        _selectedOptionIndex = null;
        _hasAnswered = false;
        _isAnswerCorrect = false;
      });
    }
  }

  void _showCompletionDialog() {
    final total = widget.worksheet.questions.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: AppColors.tertiary, size: 58),
            ),
            const SizedBox(height: 12),
            const Text(
              'शाबाश! कार्यपत्रक पूरा हुआ!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! (All questions completed!)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'कुल अंक / Score: $_score / $total',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('समाप्त (Done)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.worksheet.questions[_currentIndex];
    final total = widget.worksheet.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'प्रश्न ${_currentIndex + 1} / $total',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linear Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (_currentIndex + 1) / total,
                minHeight: 8,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),

            const SizedBox(height: 18),

            // Question Card with Featured Image
            PalashCard(
              elevation: 2,
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // Image Display
                  if (question.image != null) ...[
                    PalashAssetImage(
                      imagePath: question.image,
                      width: 140,
                      height: 140,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Question Text in Hindi + Santali
                  BilingualText(
                    hindi: question.questionHindi,
                    santali: question.questionSantali,
                    hindiFontSize: 19,
                    santaliFontSize: 15,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Options List
            const Text(
              'सही उत्तर चुनें (Select Answer):',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ...List.generate(question.optionsHindi.length, (index) {
              final isSelected = _selectedOptionIndex == index;
              final isCorrect = index == question.correctIndex;

              Color borderColor = AppColors.border;
              Color bgColor = Colors.white;

              if (_hasAnswered) {
                if (isSelected) {
                  borderColor = isCorrect ? AppColors.success : AppColors.error;
                  bgColor = isCorrect ? AppColors.successContainer : AppColors.errorContainer;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PalashCard(
                  backgroundColor: bgColor,
                  borderColor: borderColor,
                  borderRadius: 16,
                  elevation: isSelected ? 2 : 0,
                  onTap: () => _handleOptionSelect(index),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isCorrect ? AppColors.success : AppColors.error)
                              : AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: BilingualText(
                          hindi: question.optionsHindi[index],
                          santali: question.optionsSantali[index],
                          hindiFontSize: 16,
                          santaliFontSize: 14,
                        ),
                      ),
                      if (_hasAnswered && isSelected)
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? AppColors.success : AppColors.error,
                          size: 26,
                        ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // Immediate Corrective Feedback Banner
            if (_hasAnswered)
              FeedbackBanner(
                isCorrect: _isAnswerCorrect,
                explanationHindi: question.explanationHindi,
                explanationSantali: question.explanationSantali,
                onAction: _handleNextOrRetry,
              ),
          ],
        ),
      ),
    );
  }
}
