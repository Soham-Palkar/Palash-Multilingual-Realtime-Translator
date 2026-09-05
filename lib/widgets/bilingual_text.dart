import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Renders Hindi and Santali text in a clean bilingual layout
class BilingualText extends StatelessWidget {
  final String hindi;
  final String santali;
  final String? santaliOlChiki;
  final double hindiFontSize;
  final double santaliFontSize;
  final FontWeight hindiWeight;
  final FontWeight santaliWeight;
  final Color? hindiColor;
  final Color? santaliColor;
  final TextAlign textAlign;
  final bool showDivider;

  const BilingualText({
    super.key,
    required this.hindi,
    required this.santali,
    this.santaliOlChiki,
    this.hindiFontSize = 18,
    this.santaliFontSize = 16,
    this.hindiWeight = FontWeight.bold,
    this.santaliWeight = FontWeight.w600,
    this.hindiColor,
    this.santaliColor,
    this.textAlign = TextAlign.start,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hindi Primary Text
        Text(
          hindi,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: hindiFontSize,
            fontWeight: hindiWeight,
            color: hindiColor ?? AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 3),
        // Santali Vernacular Text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (santaliColor ?? AppColors.secondary).withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            santali,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: santaliFontSize,
              fontWeight: santaliWeight,
              color: santaliColor ?? AppColors.secondary,
              height: 1.3,
            ),
          ),
        ),
        if (santaliOlChiki != null && santaliOlChiki!.trim().isNotEmpty && santaliOlChiki != santali) ...[
          const SizedBox(height: 2),
          Text(
            'ᱚᱞ ᱪᱤᱠᱤ: $santaliOlChiki',
            textAlign: textAlign,
            style: TextStyle(
              fontSize: santaliFontSize * 0.9,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (showDivider) ...[
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
