import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ai_content_model.dart';
import '../../../repositories/teacher_repository.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class ContentReviewScreen extends StatefulWidget {
  const ContentReviewScreen({super.key});

  @override
  State<ContentReviewScreen> createState() => _ContentReviewScreenState();
}

class _ContentReviewScreenState extends State<ContentReviewScreen> {
  List<AIGeneratedContent> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final repo = Provider.of<TeacherRepository>(context, listen: false);
    final list = await repo.getAIGeneratedContents();
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'सामग्री समीक्षा / Content Review',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyStateView(
                  title: 'समीक्षा हेतु कोई सामग्री नहीं है',
                  subtitle: 'AI सामग्री जनरेटर से नया पाठ्य ड्राफ्ट तैयार करें।',
                  icon: Icons.rate_review_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    Color badgeColor = AppColors.tertiary;
                    String badgeLabel = 'ड्राफ्ट (DRAFT)';
                    if (item.state == ContentState.approved) {
                      badgeColor = AppColors.info;
                      badgeLabel = 'स्वीकृत (APPROVED)';
                    } else if (item.state == ContentState.published) {
                      badgeColor = AppColors.secondary;
                      badgeLabel = 'प्रकाशित (PUBLISHED)';
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PalashCard(
                        elevation: 1,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.teacherDraftReview,
                            arguments: {'aiContent': item},
                          ).then((_) => _loadItems());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.noteTitle,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: badgeColor),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.explanationHindi,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  '${item.flashcards.length} फ्लैशकार्ड्स • ${item.practiceQuestions.length} प्रश्न',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'समीक्षा करें →',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
