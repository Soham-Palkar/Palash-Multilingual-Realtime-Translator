import 'dart:math';
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
  // State for match_word_image (interactive question-by-question)
  int _wordImageCurrentIndex = 0;
  int _wordImageScore = 0;
  int? _wordImageSelectedOption;
  bool _wordImageAnswered = false;

  // State for shape_matching
  int _shapeCurrentIndex = 0;
  int _shapeScore = 0;
  int? _shapeSelectedOption;
  bool _shapeAnswered = false;

  // State for arrange_sentence
  final List<int> _selectedWordsOrder = [];

  // State for count_objects
  int? _selectedCount;

  // State for choose_image
  String? _selectedImageId;

  // State for memory_cards
  List<Map<String, dynamic>> _memoryCards = [];
  int? _firstFlippedIndex;
  int? _secondFlippedIndex;
  final List<int> _matchedIndices = [];

  // State for letter_matching
  List<Map<String, dynamic>> _letterPairs = [];
  List<String> _shuffledSantaliLetters = [];
  int? _selectedHindiIndex;
  int? _selectedSantaliIndex;
  final Set<int> _matchedHindiIndices = {};
  final Set<int> _matchedSantaliIndices = {};

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
    } else if (type == 'letter_matching') {
      final pairs = (widget.game.rawData['pairs'] as List? ?? []);
      _letterPairs = pairs
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      _shuffledSantaliLetters = _letterPairs
          .map((p) => (p['santali'] ?? '') as String)
          .toList();
      _shuffledSantaliLetters.shuffle(Random());
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
              decoration: const BoxDecoration(
                color: AppColors.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: AppColors.tertiary,
                size: 54,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              messageHindi ?? 'शाबाश! आपने खेल पूरा किया!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          messageSantali ??
              'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱟᱢ ᱠᱷᱮᱞᱚᱸᱰ ᱮᱢ ᱡᱤᱛᱠᱟᱹᱨ ᱮᱱᱟ (Great Victory!)',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
            else if (widget.game.gameType == 'shape_matching')
              _buildShapeMatchingGame()
            else
              _buildWordImageMatchingGame(),
          ],
        ),
      ),
    );
  }

  // 1. Choose Image Game (e.g. Find the Cow / Find the Fruit)
  Widget _buildChooseImageGame() {
    final promptHindi =
        widget.game.rawData['promptHindi'] ?? 'सही चित्र पहचानें:';
    final promptSantali =
        widget.game.rawData['promptSantali'] ?? 'ᱴᱷᱤᱠ ᱪᱤᱛᱟᱹᱨ ᱵᱟᱪᱷᱟᱣ ᱢᱮ:';
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
                });

                if (isCorrect) {
                  _showWinDialog(
                    messageHindi: '✓ सही उत्तर! यह ${opt['nameHindi']} है।',
                    messageSantali:
                        '✓ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱱᱚᱣᱟ ᱫᱚ ${opt['nameSantali']} ᱠᱟᱱᱟ᱾',
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
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 2.5 : 1.5,
                  ),
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
                      assetKey: opt['id'],
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

  // 2. Count Objects Game (Interactive 1-10 counting)
  Widget _buildCountObjectsGame() {
    final target = (widget.game.rawData['targetCount'] as int?) ?? 4;
    final itemImg = widget.game.rawData['itemImage'];
    final nameHindi = widget.game.rawData['itemNameHindi'] ?? 'आम';
    final nameSantali = widget.game.rawData['itemNameSantali'] ?? 'ᱩᱞ (Ul)';
    final options = (widget.game.rawData['options'] as List? ?? [2, 3, 4, 5]);

    return Column(
      children: [
        Text(
          'इन $nameHindi ($nameSantali) को गिनें और सही संख्या चुनें:',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Items display grid
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(target, (index) {
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
                      messageHindi: widget.game.rawData['hindiFeedback'] ?? 'शाबाश! आपने सही गिना!',
                      messageSantali: widget.game.rawData['santaliFeedback'] ?? 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ!',
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
    final wordsHindi =
        (widget.game.rawData['wordsHindi'] as List? ??
        ['जाता हूँ', 'मैं', 'स्कूल']);
    final correctOrder =
        (widget.game.rawData['correctOrderHindi'] as List? ?? [1, 2, 0]);

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
              side: BorderSide(
                color: isUsed ? Colors.transparent : AppColors.border,
              ),
              onPressed: isUsed
                  ? null
                  : () {
                      setState(() {
                        _selectedWordsOrder.add(index);
                      });

                      if (_selectedWordsOrder.length == correctOrder.length) {
                        bool correct = true;
                        for (int i = 0; i < correctOrder.length; i++) {
                          if (_selectedWordsOrder[i] != correctOrder[i]) {
                            correct = false;
                          }
                        }
                        if (correct) {
                          _showWinDialog(
                            messageHindi:
                                'शाबाश! सही वाक्य: "${widget.game.rawData['sentenceHindi']}"',
                            messageSantali:
                                'ᱥᱟᱱᱛᱟᱲᱤ: "${widget.game.rawData['sentenceSantali']}"',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text(
                                '✗ क्रम सही नहीं है। पुनः प्रयास करें!',
                              ),
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
        final isFlipped =
            index == _firstFlippedIndex ||
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
                  _matchedIndices.addAll([
                    _firstFlippedIndex!,
                    _secondFlippedIndex!,
                  ]);
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
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        card['santali'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
          ),
        );
      },
    );
  }

  // 5. Letter Matching Game (Interactive matching)
  Widget _buildLetterMatchingGame() {
    return Column(
      children: [
        const Text(
          'देवनागरी अक्षर छूकर उसका सही ओल चिकी अक्षर जोड़ें:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Hindi Letters
            Expanded(
              child: Column(
                children: List.generate(_letterPairs.length, (hIdx) {
                  final pair = _letterPairs[hIdx];
                  final isMatched = _matchedHindiIndices.contains(hIdx);
                  final isSelected = _selectedHindiIndex == hIdx;

                  Color bgColor = Colors.white;
                  Color borderColor = AppColors.border;
                  if (isMatched) {
                    bgColor = AppColors.successContainer.withOpacity(0.5);
                    borderColor = AppColors.success;
                  } else if (isSelected) {
                    bgColor = AppColors.primaryContainer;
                    borderColor = AppColors.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: isMatched
                          ? null
                          : () {
                              setState(() {
                                _selectedHindiIndex = hIdx;
                                _checkLetterMatch();
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected || isMatched ? 2.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            pair['hindi'] ?? '',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isMatched ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 16),
            // Right Column: Shuffled Santali Ol Chiki Letters
            Expanded(
              child: Column(
                children: List.generate(_shuffledSantaliLetters.length, (sIdx) {
                  final santaliLetter = _shuffledSantaliLetters[sIdx];
                  final isMatched = _matchedSantaliIndices.contains(sIdx);
                  final isSelected = _selectedSantaliIndex == sIdx;

                  Color bgColor = Colors.white;
                  Color borderColor = AppColors.border;
                  if (isMatched) {
                    bgColor = AppColors.successContainer.withOpacity(0.5);
                    borderColor = AppColors.success;
                  } else if (isSelected) {
                    bgColor = AppColors.secondaryContainer;
                    borderColor = AppColors.secondary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: isMatched
                          ? null
                          : () {
                              setState(() {
                                _selectedSantaliIndex = sIdx;
                                _checkLetterMatch();
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected || isMatched ? 2.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            santaliLetter,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isMatched ? AppColors.success : AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _checkLetterMatch() {
    if (_selectedHindiIndex != null && _selectedSantaliIndex != null) {
      final expectedSantali = _letterPairs[_selectedHindiIndex!]['santali'];
      final selectedSantali = _shuffledSantaliLetters[_selectedSantaliIndex!];

      if (expectedSantali == selectedSantali) {
        _matchedHindiIndices.add(_selectedHindiIndex!);
        _matchedSantaliIndices.add(_selectedSantaliIndex!);
        _selectedHindiIndex = null;
        _selectedSantaliIndex = null;

        if (_matchedHindiIndices.length == _letterPairs.length) {
          _showWinDialog(
            messageHindi: 'शाबाश! आपने सभी अक्षरों का सही मिलान किया!',
            messageSantali: 'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱡᱚᱛᱚ ᱟᱠᱷᱚᱨ ᱢᱤᱞᱟᱹᱣ ᱮᱱᱟ!',
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            duration: Duration(milliseconds: 900),
            content: Text('✗ मिलान सही नहीं है, पुनः प्रयास करें!'),
          ),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _selectedHindiIndex = null;
              _selectedSantaliIndex = null;
            });
          }
        });
      }
    }
  }

  // 6. Interactive Shape Matching Game
  Widget _buildShapeMatchingGame() {
    final shapes = (widget.game.rawData['shapes'] as List? ?? []);
    if (shapes.isEmpty) return const Text('आकृति उपलब्ध नहीं है');

    final currentShape = shapes[_shapeCurrentIndex % shapes.length];
    final shapeImg = currentShape['image'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'प्रश्न ${_shapeCurrentIndex + 1} / ${shapes.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'अंक: $_shapeScore',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.moduleMath, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              PalashAssetImage(
                imagePath: shapeImg,
                width: 110,
                height: 110,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 14),
              const Text(
                'यह कौन सी आकृति है? (Which shape is this?)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: List.generate(shapes.length, (optIdx) {
            final opt = shapes[optIdx];
            final isCorrect = optIdx == (_shapeCurrentIndex % shapes.length);
            final isSelected = _shapeSelectedOption == optIdx;

            Color bgColor = Colors.white;
            Color borderColor = AppColors.border;

            if (_shapeAnswered) {
              if (isCorrect) {
                bgColor = AppColors.successContainer.withOpacity(0.6);
                borderColor = AppColors.success;
              } else if (isSelected) {
                bgColor = AppColors.errorContainer.withOpacity(0.6);
                borderColor = AppColors.error;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _shapeAnswered
                    ? null
                    : () {
                        setState(() {
                          _shapeSelectedOption = optIdx;
                          _shapeAnswered = true;
                          if (isCorrect) _shapeScore++;
                        });

                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) {
                            if (_shapeCurrentIndex + 1 < shapes.length) {
                              setState(() {
                                _shapeCurrentIndex++;
                                _shapeSelectedOption = null;
                                _shapeAnswered = false;
                              });
                            } else {
                              _showWinDialog(
                                messageHindi: 'शाबाश! आपने $_shapeScore / ${shapes.length} सही उत्तर दिए!',
                              );
                            }
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Text(
                    '${opt['nameHindi']} (${opt['nameSantali']})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 7. Interactive Word & Image Matching Game
  Widget _buildWordImageMatchingGame() {
    final items = (widget.game.rawData['items'] as List? ?? []);
    if (items.isEmpty) return const Text('खेल सामग्री उपलब्ध नहीं है');

    final currentIndex = _wordImageCurrentIndex % items.length;
    final currentItem = items[currentIndex];
    final currentImg = currentItem['image'] ?? currentItem['imageKey'];

    // Create 4 deterministic options from items
    final List<Map<String, dynamic>> options = [];
    options.add(Map<String, dynamic>.from(currentItem as Map));
    for (var it in items) {
      if (options.length < 4 && it['hindi'] != currentItem['hindi']) {
        options.add(Map<String, dynamic>.from(it as Map));
      }
    }
    // Deterministic shuffle based on current question index
    options.shuffle(Random(currentIndex * 7));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'प्रश्न ${currentIndex + 1} / ${items.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              'अंक: $_wordImageScore',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              PalashAssetImage(
                imagePath: currentImg,
                assetKey: currentItem['imageKey'] ?? currentItem['id'],
                width: 120,
                height: 120,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(height: 12),
              const Text(
                'यह क्या है? सही नाम चुनें (Select Correct Name):',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Column(
          children: List.generate(options.length, (optIdx) {
            final opt = options[optIdx];
            final isCorrect = opt['hindi'] == currentItem['hindi'];
            final isSelected = _wordImageSelectedOption == optIdx;

            Color bgColor = Colors.white;
            Color borderColor = AppColors.border;

            if (_wordImageAnswered) {
              if (isCorrect) {
                bgColor = AppColors.successContainer.withOpacity(0.6);
                borderColor = AppColors.success;
              } else if (isSelected) {
                bgColor = AppColors.errorContainer.withOpacity(0.6);
                borderColor = AppColors.error;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: _wordImageAnswered
                    ? null
                    : () {
                        setState(() {
                          _wordImageSelectedOption = optIdx;
                          _wordImageAnswered = true;
                          if (isCorrect) _wordImageScore++;
                        });

                        Future.delayed(const Duration(milliseconds: 1000), () {
                          if (mounted) {
                            if (_wordImageCurrentIndex + 1 < items.length) {
                              setState(() {
                                _wordImageCurrentIndex++;
                                _wordImageSelectedOption = null;
                                _wordImageAnswered = false;
                              });
                            } else {
                              _showWinDialog(
                                messageHindi: 'शाबाश! आपने $_wordImageScore / ${items.length} सही उत्तर दिए!',
                              );
                            }
                          }
                        });
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        opt['hindi'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        opt['santali'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

