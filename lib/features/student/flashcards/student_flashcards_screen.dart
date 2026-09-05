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
  bool _isDeckMode = true;
  int _currentCardIndex = 0;
  bool _isFlipped = false;

  final List<String> _categories = [
    'General Knowledge',
    'Language',
    'Mathematics',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedSubcategory = 'All';
          _currentCardIndex = 0;
          _isFlipped = false;
        });
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

  void _nextCard(int total) {
    if (total == 0) return;
    setState(() {
      _currentCardIndex = (_currentCardIndex + 1) % total;
      _isFlipped = false;
    });
  }

  void _prevCard(int total) {
    if (total == 0) return;
    setState(() {
      _currentCardIndex = (_currentCardIndex - 1 + total) % total;
      _isFlipped = false;
    });
  }

  void _playPronunciation(FlashcardItem card) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '🔊 ${card.pronunciation ?? "${card.hindi} • ${card.santali}"}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'चित्र फ्लैशकार्ड्स / Flashcards',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isDeckMode ? Icons.grid_view_rounded : Icons.view_carousel_rounded,
              color: AppColors.primary,
            ),
            tooltip: _isDeckMode ? 'ग्रिड देखें (Grid View)' : 'डेक देखें (Deck View)',
            onPressed: () {
              setState(() => _isDeckMode = !_isDeckMode);
            },
          ),
          const Padding(
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'सामान्य ज्ञान (GK)'),
            Tab(text: 'भाषा (Language)'),
            Tab(text: 'गणित (Math)'),
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

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    title: 'कोई फ्लैशकार्ड नहीं मिला',
                    subtitle: 'इस श्रेणी के फ्लैशकार्ड शीघ्र लोड होंगे।',
                    icon: Icons.style_outlined,
                  );
                }

                final activeIndex = _currentCardIndex >= filtered.length
                    ? 0
                    : _currentCardIndex;

                return Column(
                  children: [
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
                                    if (sel) {
                                      setState(() {
                                        _selectedSubcategory = sub;
                                        _currentCardIndex = 0;
                                        _isFlipped = false;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: _isDeckMode
                          ? _buildDeckView(filtered, activeIndex)
                          : _buildGridView(filtered),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildDeckView(List<FlashcardItem> cards, int index) {
    final card = cards[index];
    final total = cards.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  card.subcategory,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                'कार्ड ${index + 1} / $total',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (index + 1) / total,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _isFlipped = !_isFlipped);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _isFlipped
                      ? AppColors.secondaryContainer.withOpacity(0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _isFlipped
                        ? AppColors.secondary
                        : AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PalashAssetImage(
                      imagePath: card.image,
                      iconName: card.iconName,
                      width: 150,
                      height: 150,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      card.hindi,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        card.santali,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    if (card.santaliOlChiki != null &&
                        card.santaliOlChiki!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ᱚᱞ ᱪᱤᱠᱤ: ${card.santaliOlChiki}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (_isFlipped && card.linguistNote != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        card.linguistNote!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _playPronunciation(card),
                          icon: const Icon(Icons.volume_up_rounded, size: 18),
                          label: const Text('उच्चारण (Pronounce)'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 36),
                            side: const BorderSide(color: AppColors.secondary),
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _prevCard(total),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text('पिछला (Prev)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _nextCard(total),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text('अगला (Next)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<FlashcardItem> cards) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _FlashcardFlipTile(
          card: card,
          onTap: () {
            setState(() {
              _currentCardIndex = index;
              _isDeckMode = true;
            });
          },
        );
      },
    );
  }
}

class _FlashcardFlipTile extends StatelessWidget {
  final FlashcardItem card;
  final VoidCallback onTap;

  const _FlashcardFlipTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
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
                    card.subcategory,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_full_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            PalashAssetImage(
              imagePath: card.image,
              iconName: card.iconName,
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(14),
            ),
            Column(
              children: [
                Text(
                  card.hindi,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    card.santali,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
