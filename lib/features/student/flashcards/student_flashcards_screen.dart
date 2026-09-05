import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/flashcard_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_asset_image.dart';

class StudentFlashcardsScreen extends StatefulWidget {
  const StudentFlashcardsScreen({super.key});

  @override
  State<StudentFlashcardsScreen> createState() => _StudentFlashcardsScreenState();
}

class _StudentFlashcardsScreenState extends State<StudentFlashcardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FlashcardItem> _allFlashcards = [];
  bool _isLoading = true;
  String _selectedSubcategory = 'All';

  final List<String> _categories = [
    'Language',
    'Mathematics',
    'General Knowledge',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedSubcategory = 'All');
      }
    });
    _loadFlashcards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    final repo = Provider.of<ContentRepository>(context, listen: false);
    final list = await repo.getAllPublishedFlashcards();
    if (mounted) {
      setState(() {
        _allFlashcards = list;
        _isLoading = false;
      });
    }
  }

  List<FlashcardItem> _getFilteredCards(String category) {
    var list = _allFlashcards
        .where((f) => f.category.toLowerCase() == category.toLowerCase())
        .toList();
    if (_selectedSubcategory != 'All') {
      list = list.where((f) => f.subcategory == _selectedSubcategory).toList();
    }
    return list;
  }

  List<String> _getSubcategories(String category) {
    final subcats = _allFlashcards
        .where((f) => f.category.toLowerCase() == category.toLowerCase())
        .map((f) => f.subcategory)
        .toSet()
        .toList();
    return ['All', ...subcats];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'चित्र फ्लैशकार्ड्स / Flashcards',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'भाषा (Language)'),
            Tab(text: 'गणित (Math)'),
            Tab(text: 'सामान्य ज्ञान (GK)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final filtered = _getFilteredCards(cat);
                final subcategories = _getSubcategories(cat);

                return Column(
                  children: [
                    // Subcategory selector
                    if (subcategories.length > 1)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: subcategories.map((sub) {
                              final isSelected = _selectedSubcategory == sub;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(sub == 'All' ? 'सभी (All)' : sub),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                  onSelected: (sel) {
                                    if (sel) setState(() => _selectedSubcategory = sub);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),


                    const Divider(height: 1, color: AppColors.border),

                    // Flashcard Grid
                    Expanded(
                      child: filtered.isEmpty
                          ? const EmptyStateView(
                              title: 'कोई फ्लैशकार्ड नहीं मिला',
                              subtitle: 'इस श्रेणी के फ्लैशकार्ड शीघ्र लोड होंगे।',
                              icon: Icons.style_outlined,
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.82,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final card = filtered[index];
                                return _FlashcardFlipTile(card: card);
                              },
                            ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }
}

class _FlashcardFlipTile extends StatefulWidget {
  final FlashcardItem card;

  const _FlashcardFlipTile({required this.card});

  @override
  State<_FlashcardFlipTile> createState() => _FlashcardFlipTileState();
}

class _FlashcardFlipTileState extends State<_FlashcardFlipTile> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _showBack = !_showBack);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _showBack
              ? AppColors.secondaryContainer.withOpacity(0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _showBack
                ? AppColors.secondary
                : AppColors.primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.card.subcategory,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                Icon(
                  _showBack ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),

            // Card Graphic
            PalashAssetImage(
              imagePath: widget.card.image,
              iconName: widget.card.iconName,
              width: 75,
              height: 75,
              borderRadius: BorderRadius.circular(14),
            ),

            // Bilingual Text (Hindi + Santali)
            Column(
              children: [
                Text(
                  widget.card.hindi,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.card.santali,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                if (widget.card.santaliOlChiki != null &&
                    widget.card.santaliOlChiki!.isNotEmpty &&
                    _showBack) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ᱚᱞ ᱪᱤᱠᱤ: ${widget.card.santaliOlChiki}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
