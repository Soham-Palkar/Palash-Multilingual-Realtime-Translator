import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'bilingual_text.dart';

/// Interactive immediate feedback banner for worksheets and learning tasks
class FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String explanationHindi;
  final String explanationSantali;
  final VoidCallback onAction;
  final String? customActionLabel;

  const FeedbackBanner({
    super.key,
    required this.isCorrect,
    required this.explanationHindi,
    required this.explanationSantali,
    required this.onAction,
    this.customActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect ? AppColors.successContainer : AppColors.errorContainer;
    final borderColor = isCorrect ? AppColors.success : AppColors.error;
    final iconColor = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? AppStrings.correctTitle : AppStrings.incorrectTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    Text(
                      isCorrect ? AppStrings.correctSantali : AppStrings.incorrectSantali,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: iconColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          BilingualText(
            hindi: explanationHindi,
            santali: explanationSantali,
            hindiFontSize: 15,
            santaliFontSize: 14,
            hindiWeight: FontWeight.w500,
            santaliWeight: FontWeight.w500,
            santaliColor: isCorrect ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                isCorrect ? Icons.arrow_forward_rounded : Icons.refresh_rounded,
              ),
              label: Text(
                customActionLabel ??
                    (isCorrect ? AppStrings.nextQuestion : AppStrings.tryAgain),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
