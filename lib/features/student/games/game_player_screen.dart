import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/game_model.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/palash_asset_image.dart';
import '../../../widgets/palash_card.dart';

class GamePlayerScreen extends StatefulWidget {
  final GameItem game;

  const GamePlayerScreen({super.key, required this.game});

  @override
  State<GamePlayerScreen> createState() => _GamePlayerScreenState();
}

class _GamePlayerScreenState extends State<GamePlayerScreen> {
  // State for arrange_sentence
  final List<int> _selectedWordsOrder = [];

  // State for count_objects
  int? _selectedCount;

  // State for choose_image
  String? _selectedImageId;
  bool? _isImageCorrect;

  // State for memory_cards
  List<Map<String, dynamic>> _memoryCards = [];
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  final List<int> _matchedIndices = [];

  @override
  void initState() {
    super.initState();
    _initGameData();
  }

  void _initGameData() {
    final type = widget.game.gameType;
    if (type == 'memory_cards') {
      final rawCards = (widget.game.rawData['cards'] as List? ?? []);
      _memoryCards = rawCards
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();
      _memoryCards.shuffle();
    }
  }

  void _showWinDialog({String? messageHindi, String? messageSantali}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: AppColors.tertiary, size: 54),
            ),
            const SizedBox(height: 12),
            Text(
              messageHindi ?? 'शाबाश! आपने सही उत्तर दिया!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          messageSantali ?? 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱟᱢ ᱠᱷᱮᱞᱚᱸᱰ ᱮᱢ ᱡᱤᱛᱠᱟᱹᱨ ᱮᱱᱟ (Great Victory!)',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
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
            child: const Text('वापस जाएँ (Done)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.game.titleHindi,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game Header Card
            PalashCard(
              backgroundColor: AppColors.moduleGames.withOpacity(0.08),
              borderColor: AppColors.moduleGames.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: BilingualText(
                hindi: widget.game.descriptionHindi,
                santali: widget.game.descriptionSantali,
                hindiFontSize: 15,
                santaliFontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            // Render Game according to type
            if (widget.game.gameType == 'choose_image')
              _buildChooseImageGame()
            else if (widget.game.gameType == 'count_objects')
              _buildCountObjectsGame()
            else if (widget.game.gameType == 'arrange_sentence')
              _buildArrangeSentenceGame()
            else if (widget.game.gameType == 'memory_cards')
              _buildMemoryCardGame()
            else if (widget.game.gameType == 'letter_matching')
              _buildLetterMatchingGame()
            else
              _buildWordImageMatchingGame(),
          ],
        ),
      ),
    );
  }

  // 1. Choose Image Game (e.g. Find the Cow / Find the Fruit)
  Widget _buildChooseImageGame() {
    final promptHindi = widget.game.rawData['promptHindi'] ?? 'सही चित्र पहचानें:';
    final promptSantali = widget.game.rawData['promptSantali'] ?? 'ᱴᱷᱤᱠ ᱪᱤᱛᱟᱹᱨ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
    final options = (widget.game.rawData['options'] as List? ?? []);

    return Column(
      children: [
        PalashCard(
          backgroundColor: Colors.white,
          borderColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: BilingualText(
            hindi: promptHindi,
            santali: promptSantali,
            hindiFontSize: 18,
            santaliFontSize: 15,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.95,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final optId = opt['id'] as String? ?? '$index';
            final isCorrect = opt['isCorrect'] as bool? ?? false;
            final isSelected = _selectedImageId == optId;

            Color borderColor = AppColors.border;
            Color bgColor = Colors.white;

            if (isSelected) {
              borderColor = isCorrect ? AppColors.success : AppColors.error;
              bgColor = isCorrect
                  ? AppColors.successContainer.withOpacity(0.5)
                  : AppColors.errorContainer.withOpacity(0.5);
            }

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedImageId = optId;
                  _isImageCorrect = isCorrect;
                });

                if (isCorrect) {
                  _showWinDialog(
                    messageHindi: '✓ सही उत्तर! यह ${opt['nameHindi']} है।',
                    messageSantali: '✓ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱱᱚᱣᱟ ᱫᱚ ${opt['nameSantali']} ᱠᱟᱱᱟ᱾',
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text('✗ फिर से कोशिश करो! (Try again!)'),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PalashAssetImage(
                      imagePath: opt['image'],
                      width: 80,
                      height: 80,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opt['nameHindi'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      opt['nameSantali'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. Count Objects Game
  Widget _buildCountObjectsGame() {
    final target = widget.game.rawData['targetCount'] ?? 4;
    final itemImg = widget.game.rawData['itemImage'];
    final nameHindi = widget.game.rawData['itemNameHindi'] ?? 'आम';
    final nameSantali = widget.game.rawData['itemNameSantali'] ?? 'ᱩᱞ (Ul)';
    final options = (widget.game.rawData['options'] as List? ?? [2, 3, 4, 5]);

    return Column(
      children: [
        Text(
          'इन $nameHindi ($nameSantali) को गिनें:',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Items display grid
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(target as int, (index) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tertiary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: PalashAssetImage(
                imagePath: itemImg,
                width: 65,
                height: 65,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        const Text(
          'सही संख्या चुनें (Choose Number):',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: options.map((opt) {
            final isSelected = _selectedCount == opt;
            final isCorrect = opt == target;

            Color btnColor = AppColors.moduleMath;
            if (isSelected) {
              btnColor = isCorrect ? AppColors.success : AppColors.error;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCount = opt);
                  if (opt == target) {
                    _showWinDialog(
                      messageHindi: widget.game.rawData['hindiFeedback'],
                      messageSantali: widget.game.rawData['santaliFeedback'],
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text('✗ पुनः गिनिए! (Try counting again)'),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isSelected ? btnColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: btnColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$opt',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : btnColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 3. Arrange Sentence Game
  Widget _buildArrangeSentenceGame() {
    final wordsHindi = (widget.game.rawData['wordsHindi'] as List? ?? ['जाता हूँ', 'मैं', 'स्कूल']);
    final correctOrder = (widget.game.rawData['correctOrderHindi'] as List? ?? [1, 2, 0]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'वाक्य पूरा करने के लिए शब्दों को सही क्रम में छुएं:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Arranged sentence box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.moduleLanguage, width: 1.5),
          ),
          child: _selectedWordsOrder.isEmpty
              ? const Center(
                  child: Text(
                    '[ शब्दों को नीचे से चुनें ]',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedWordsOrder.map((idx) {
                    return Chip(
                      label: Text(
                        wordsHindi[idx],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppColors.primaryContainer,
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedWordsOrder.remove(idx);
                        });
                      },
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: 20),

        // Available Words Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(wordsHindi.length, (index) {
            final isUsed = _selectedWordsOrder.contains(index);
            return ActionChip(
              label: Text(
                wordsHindi[index],
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isUsed ? Colors.grey : AppColors.textPrimary,
                ),
              ),
              backgroundColor: isUsed ? Colors.grey.shade200 : Colors.white,
              side: BorderSide(color: isUsed ? Colors.transparent : AppColors.border),
              onPressed: isUsed
                  ? null
                  : () {
                      setState(() {
                        _selectedWordsOrder.add(index);
                      });

                      if (_selectedWordsOrder.length == correctOrder.length) {
                        bool correct = true;
                        for (int i = 0; i < correctOrder.length; i++) {
                          if (_selectedWordsOrder[i] != correctOrder[i]) correct = false;
                        }
                        if (correct) {
                          _showWinDialog(
                            messageHindi: 'शाबाश! सही वाक्य: "${widget.game.rawData['sentenceHindi']}"',
                            messageSantali: 'ᱥᱟᱱᱛᱟᱲᱤ: "${widget.game.rawData['sentenceSantali']}"',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text('✗ क्रम सही नहीं है। पुनः प्रयास करें!'),
                            ),
                          );
                        }
                      }
                    },
            );
          }),
        ),
      ],
    );
  }

  // 4. Memory Cards Match
  Widget _buildMemoryCardGame() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _memoryCards.length,
      itemBuilder: (context, index) {
        final card = _memoryCards[index];
        final isFlipped = index == _firstFlippedIndex ||
            index == _secondFlippedIndex ||
            _matchedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            if (_matchedIndices.contains(index) ||
                index == _firstFlippedIndex ||
                _secondFlippedIndex != null) {
              return;
            }

            setState(() {
              if (_firstFlippedIndex == null) {
                _firstFlippedIndex = index;
              } else {
                _secondFlippedIndex = index;

                final firstCard = _memoryCards[_firstFlippedIndex!];
                final secondCard = _memoryCards[_secondFlippedIndex!];

                if (firstCard['pairId'] == secondCard['pairId']) {
                  _matchedIndices.addAll([_firstFlippedIndex!, _secondFlippedIndex!]);
                  _firstFlippedIndex = null;
                  _secondFlippedIndex = null;

                  if (_matchedIndices.length == _memoryCards.length) {
                    _showWinDialog();
                  }
                } else {
                  Future.delayed(const Duration(milliseconds: 900), () {
                    if (mounted) {
                      setState(() {
                        _firstFlippedIndex = null;
                        _secondFlippedIndex = null;
                      });
                    }
                  });
                }
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isFlipped ? Colors.white : AppColors.moduleGames,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFlipped ? AppColors.secondary : AppColors.moduleGames,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: isFlipped
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PalashAssetImage(
                        imagePath: card['image'],
                        width: 50,
                        height: 50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card['hindi'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        card['santali'] ?? '',
                        style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : const Center(
                    child: Icon(Icons.help_outline_rounded, color: Colors.white, size: 36),
                  ),
          ),
        );
      },
    );
  }

  // 5. Letter Matching Game
  Widget _buildLetterMatchingGame() {
    final pairs = (widget.game.rawData['pairs'] as List? ?? []);

    return Column(
      children: pairs.map((pair) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PalashCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pair['hindi'] ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    pair['santali'] ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 6. Word Image Match
  Widget _buildWordImageMatchingGame() {
    final items = (widget.game.rawData['items'] as List? ?? []);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PalashCard(
            child: Row(
              children: [
                PalashAssetImage(
                  imagePath: item['image'],
                  width: 58,
                  height: 58,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: BilingualText(
                    hindi: item['hindi'] ?? '',
                    santali: item['santali'] ?? '',
                    hindiFontSize: 16,
                    santaliFontSize: 13,
                  ),
                ),
                const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 26),
              ],
            ),
          ),
        );
      },
    );
  }
}
