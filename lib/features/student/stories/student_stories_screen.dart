import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/story_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_asset_image.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class StudentStoriesScreen extends StatefulWidget {
  const StudentStoriesScreen({super.key});

  @override
  State<StudentStoriesScreen> createState() => _StudentStoriesScreenState();
}

class _StudentStoriesScreenState extends State<StudentStoriesScreen> {
  List<StoryItem> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final repo = Provider.of<ContentRepository>(context, listen: false);
    final list = await repo.getStories();
    if (mounted) {
      setState(() {
        _stories = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'चित्र कहानियाँ / Stories',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? const EmptyStateView(
                  title: 'कोई कहानी नहीं मिली',
                  subtitle: 'कहानियाँ शीघ्र लोड होंगी।',
                  icon: Icons.auto_stories_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _stories.length,
                  itemBuilder: (context, index) {
                    final story = _stories[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PalashCard(
                        elevation: 2,
                        padding: EdgeInsets.zero,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.studentStoryReader,
                            arguments: story,
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.moduleStories.withOpacity(0.15),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: PalashAssetImage(
                                  imagePath: story.coverImage,
                                  width: 90,
                                  height: 90,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BilingualText(
                                    hindi: story.titleHindi,
                                    santali: story.titleSantali,
                                    hindiFontSize: 17,
                                    santaliFontSize: 14,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '📖 ${story.pages.length} पृष्ठ (Pages)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text(
                                        'कहानी पढ़ें →',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
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
    );
  }
}
