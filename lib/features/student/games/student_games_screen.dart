import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class StudentGamesScreen extends StatefulWidget {
  const StudentGamesScreen({super.key});

  @override
  State<StudentGamesScreen> createState() => _StudentGamesScreenState();
}

class _StudentGamesScreenState extends State<StudentGamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GameItem> _games = [];
  bool _isLoading = true;

  final List<String> _categories = ['Language', 'Mathematics', 'Memory'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGames() async {
    final repo = Provider.of<ContentRepository>(context, listen: false);
    final list = await repo.getGames();
    if (mounted) {
      setState(() {
        _games = list;
        _isLoading = false;
      });
    }
  }

  List<GameItem> _getGamesForCategory(String category) {
    return _games
        .where((g) => g.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'शैक्षणिक खेल / Games',
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
          labelColor: AppColors.moduleGames,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.moduleGames,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'भाषा (Language)'),
            Tab(text: 'गणित (Math)'),
            Tab(text: 'स्मृति (Memory)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _categories.map((cat) {
                final list = _getGamesForCategory(cat);

                if (list.isEmpty) {
                  return const EmptyStateView(
                    title: 'कोई खेल नहीं मिला',
                    subtitle: 'खेल शीघ्र लोड होंगे।',
                    icon: Icons.sports_esports_outlined,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final game = list[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PalashCard(
                        elevation: 2,
                        borderColor: AppColors.moduleGames.withOpacity(0.3),
                        onTap: () {
                          if (game.isComingSoon) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔊 यह खेल शीघ्र आ रहा है (Coming Soon)!'),
                              ),
                            );
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            AppRoutes.studentGamePlayer,
                            arguments: game,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.moduleGames.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getGameIcon(game.gameType),
                                color: AppColors.moduleGames,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (game.isComingSoon)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Coming Soon (शीघ्र आ रहा है)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  BilingualText(
                                    hindi: game.titleHindi,
                                    santali: game.titleSantali,
                                    hindiFontSize: 16,
                                    santaliFontSize: 13,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    game.descriptionHindi,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              game.isComingSoon
                                  ? Icons.lock_clock_rounded
                                  : Icons.play_circle_fill_rounded,
                              color: game.isComingSoon
                                  ? AppColors.textMuted
                                  : AppColors.moduleGames,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }

  IconData _getGameIcon(String type) {
    switch (type) {
      case 'match_word_image':
        return Icons.join_inner_rounded;
      case 'letter_matching':
        return Icons.spellcheck_rounded;
      case 'arrange_sentence':
        return Icons.reorder_rounded;
      case 'listen_choose':
        return Icons.hearing_rounded;
      case 'count_objects':
        return Icons.pin_rounded;
      case 'shape_matching':
        return Icons.category_rounded;
      case 'memory_cards':
        return Icons.flip_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }
}
