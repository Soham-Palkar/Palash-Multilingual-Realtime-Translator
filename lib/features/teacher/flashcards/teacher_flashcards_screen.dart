import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/flashcard_model.dart';
import '../../../repositories/teacher_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_card.dart';
import '../../../widgets/palash_asset_image.dart';
import '../../../app/routes.dart';

class TeacherFlashcardsScreen extends StatefulWidget {
  const TeacherFlashcardsScreen({super.key});

  @override
  State<TeacherFlashcardsScreen> createState() => _TeacherFlashcardsScreenState();
}

class _TeacherFlashcardsScreenState extends State<TeacherFlashcardsScreen> {
  List<FlashcardItem> _flashcards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final repo = Provider.of<TeacherRepository>(context, listen: false);
    final list = await repo.getTeacherFlashcards();
    if (mounted) {
      setState(() {
        _flashcards = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'शिक्षक फ्लैशकार्ड स्टूडियो',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashcards.isEmpty
              ? EmptyStateView(
                  title: 'कोई शिक्षक फ्लैशकार्ड नहीं मिला',
                  subtitle: 'मैनुअल फ्लैशकार्ड टेम्पलेट का उपयोग करके नया फ्लैशकार्ड बनाएं।',
                  icon: Icons.style_outlined,
                  onRetry: () {
                    Navigator.pushNamed(context, AppRoutes.teacherManualFlashcard)
                        .then((_) => _loadFlashcards());
                  },
                  retryLabel: '+ नया फ्लैशकार्ड बनाएं',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    final card = _flashcards[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PalashCard(
                        child: Row(
                          children: [
                            PalashAssetImage(
                              imagePath: card.image,
                              width: 64,
                              height: 64,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      card.category,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  BilingualText(
                                    hindi: card.hindi,
                                    santali: card.santali,
                                    santaliOlChiki: card.santaliOlChiki,
                                    hindiFontSize: 15,
                                    santaliFontSize: 13,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.teacherManualFlashcard)
              .then((_) => _loadFlashcards());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('नया फ्लैशकार्ड बनाएं'),
        backgroundColor: AppColors.moduleMath,
        foregroundColor: Colors.white,
      ),
    );
  }
}
