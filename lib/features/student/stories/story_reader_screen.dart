import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/story_model.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/palash_asset_image.dart';
import '../../../widgets/palash_card.dart';

class StoryReaderScreen extends StatefulWidget {
  final StoryItem story;

  const StoryReaderScreen({super.key, required this.story});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = widget.story.pages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.story.titleHindi,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalPages,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, index) {
                final page = widget.story.pages[index];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Story Page Illustration
                      if (page.image != null)
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.moduleStories.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: PalashAssetImage(
                              imagePath: page.image,
                              width: 120,
                              height: 120,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Page Content Card
                      PalashCard(
                        elevation: 1,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hindi Narrative
                            Text(
                              page.hindiText,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 14),

                            // Santali Vernacular Narrative
                            Text(
                              page.santaliText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                                height: 1.5,
                              ),
                            ),

                            if (page.santaliPhonetic != null &&
                                page.santaliPhonetic!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Phonetic: ${page.santaliPhonetic}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Bar with Page Indicators and Next/Prev buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Row(
                  children: List.generate(totalPages, (i) {
                    final isActive = _currentPage == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                IconButton.filled(
                  onPressed: _currentPage < totalPages - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : () {
                          Navigator.pop(context);
                        },
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: Icon(
                    _currentPage < totalPages - 1
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.check_rounded,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
