import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/activity_model.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/palash_asset_image.dart';
import '../../../widgets/palash_card.dart';

class ActivityPlayerScreen extends StatefulWidget {
  final ActivityItem activity;

  const ActivityPlayerScreen({super.key, required this.activity});

  @override
  State<ActivityPlayerScreen> createState() => _ActivityPlayerScreenState();
}

class _ActivityPlayerScreenState extends State<ActivityPlayerScreen> {
  // State for identify_object
  int? _selectedOption;

  // State for match_concepts (interactive concept matching)
  List<Map<String, dynamic>> _pairs = [];
  List<String> _shuffledColors = [];
  int? _selectedObjectIdx;
  int? _selectedColorIdx;
  final Set<int> _matchedObjectIndices = {};
  final Set<int> _matchedColorIndices = {};

  // State for arrange_objects (interactive ranking)
  List<Map<String, dynamic>> _arrangedSteps = [];
  final List<int> _selectedStepOrder = [];

  @override
  void initState() {
    super.initState();
    _initActivityData();
  }

  void _initActivityData() {
    if (widget.activity.type == 'match_concepts') {
      final rawPairs = (widget.activity.rawData['pairs'] as List? ?? []);
      _pairs = rawPairs.map((p) => Map<String, dynamic>.from(p as Map)).toList();
      _shuffledColors = _pairs.map((p) => '${p['colorHindi']} (${p['colorSantali']})').toList();
      _shuffledColors.shuffle(Random());
    } else if (widget.activity.type == 'arrange_objects') {
      final rawSteps = (widget.activity.rawData['steps'] as List? ?? []);
      _arrangedSteps = rawSteps.map((s) => Map<String, dynamic>.from(s as Map)).toList();
    }
  }

  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Column(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.tertiary, size: 54),
            SizedBox(height: 10),
            Text(
              'बहुत अच्छा! गतिविधि पूरी हुई!',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ! ᱠᱟᱹᱢᱤᱦᱚᱨᱟ ᱢᱩᱪᱟᱹᱫ ᱮᱱᱟ (Activity Completed!)',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
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
          widget.activity.titleHindi,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Banner
            PalashCard(
              backgroundColor: AppColors.moduleActivities.withOpacity(0.08),
              borderColor: AppColors.moduleActivities.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: BilingualText(
                hindi: widget.activity.instructionsHindi,
                santali: widget.activity.instructionsSantali,
                hindiFontSize: 15,
                santaliFontSize: 13,
              ),
            ),

            const SizedBox(height: 24),

            if (widget.activity.type == 'identify_object')
              _buildIdentifyObject()
            else if (widget.activity.type == 'match_concepts')
              _buildMatchConcepts()
            else
              _buildArrangeObjects(),
          ],
        ),
      ),
    );
  }

  // 1. Identify Object Activity
  Widget _buildIdentifyObject() {
    final items = (widget.activity.rawData['items'] as List? ?? []);
    if (items.isEmpty) return const Text('गतिविधि सामग्री उपलब्ध नहीं है।');
    final firstItem = items.first;
    final promptH = firstItem['promptHindi'] ?? '';
    final promptS = firstItem['promptSantali'] ?? '';
    final options = (firstItem['options'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualText(
          hindi: promptH,
          santali: promptS,
          hindiFontSize: 18,
          santaliFontSize: 15,
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final opt = options[index];
            final isCorrect = opt['isCorrect'] == true;
            final isSelected = _selectedOption == index;

            Color borderColor = AppColors.border;
            if (isSelected) {
              borderColor = isCorrect ? AppColors.success : AppColors.error;
            }

            return PalashCard(
              borderColor: borderColor,
              borderRadius: 18,
              onTap: () {
                setState(() => _selectedOption = index);
                if (isCorrect) {
                  _showCompleteDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text('✗ पुनः पहचानें (Try again)'),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PalashAssetImage(
                    imagePath: opt['image'],
                    width: 70,
                    height: 70,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    opt['nameHindi'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    opt['nameSantali'] ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 2. Interactive Match Concepts Activity (e.g. Object to natural color)
  Widget _buildMatchConcepts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'वस्तु को छूकर उसके सही प्राकृतिक रंग से मिलाएँ:',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Objects
            Expanded(
              child: Column(
                children: List.generate(_pairs.length, (objIdx) {
                  final pair = _pairs[objIdx];
                  final isMatched = _matchedObjectIndices.contains(objIdx);
                  final isSelected = _selectedObjectIdx == objIdx;

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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: isMatched
                          ? null
                          : () {
                              setState(() {
                                _selectedObjectIdx = objIdx;
                                _checkConceptMatch();
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: isSelected || isMatched ? 2 : 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pair['objectHindi'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isMatched ? AppColors.success : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              pair['objectSantali'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 14),
            // Right: Shuffled Colors
            Expanded(
              child: Column(
                children: List.generate(_shuffledColors.length, (colIdx) {
                  final colorStr = _shuffledColors[colIdx];
                  final isMatched = _matchedColorIndices.contains(colIdx);
                  final isSelected = _selectedColorIdx == colIdx;

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
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: isMatched
                          ? null
                          : () {
                              setState(() {
                                _selectedColorIdx = colIdx;
                                _checkConceptMatch();
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: isSelected || isMatched ? 2 : 1),
                        ),
                        child: Center(
                          child: Text(
                            colorStr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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

  void _checkConceptMatch() {
    if (_selectedObjectIdx != null && _selectedColorIdx != null) {
      final expectedColor =
          '${_pairs[_selectedObjectIdx!]['colorHindi']} (${_pairs[_selectedObjectIdx!]['colorSantali']})';
      final chosenColor = _shuffledColors[_selectedColorIdx!];

      if (expectedColor == chosenColor) {
        _matchedObjectIndices.add(_selectedObjectIdx!);
        _matchedColorIndices.add(_selectedColorIdx!);
        _selectedObjectIdx = null;
        _selectedColorIdx = null;

        if (_matchedObjectIndices.length == _pairs.length) {
          _showCompleteDialog();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            duration: Duration(milliseconds: 900),
            content: Text('✗ रंग का मिलान सही नहीं है, पुनः प्रयास करें!'),
          ),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _selectedObjectIdx = null;
              _selectedColorIdx = null;
            });
          }
        });
      }
    }
  }

  // 3. Interactive Arrange Objects Activity (e.g. arrange fruits by size)
  Widget _buildArrangeObjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'फलों को छोटे से बड़े क्रम (१ से ३) में व्यवस्थित करने के लिए नीचे दिए गए फलों को सही क्रम में चुनें:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Arranged display container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.moduleActivities, width: 1.5),
          ),
          child: _selectedStepOrder.isEmpty
              ? const Center(
                  child: Text(
                    '[ नीचे दिए गए फलों को क्रम से चुनें ]',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              : Column(
                  children: List.generate(_selectedStepOrder.length, (orderIdx) {
                    final itemIdx = _selectedStepOrder[orderIdx];
                    final step = _arrangedSteps[itemIdx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.moduleActivities,
                            child: Text(
                              '${orderIdx + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${step['nameHindi']} (${step['nameSantali']})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _selectedStepOrder.removeAt(orderIdx);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        ),

        const SizedBox(height: 18),

        // Available items to pick
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_arrangedSteps.length, (index) {
            final isUsed = _selectedStepOrder.contains(index);
            final step = _arrangedSteps[index];

            return ActionChip(
              label: Text(
                '${step['nameHindi']} (${step['nameSantali']})',
                style: TextStyle(
                  fontSize: 14,
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
                        _selectedStepOrder.add(index);
                      });

                      if (_selectedStepOrder.length == _arrangedSteps.length) {
                        bool isCorrectOrder = true;
                        for (int i = 0; i < _selectedStepOrder.length; i++) {
                          final stepRank = (_arrangedSteps[_selectedStepOrder[i]]['rank'] as int?) ?? (i + 1);
                          if (stepRank != i + 1) {
                            isCorrectOrder = false;
                          }
                        }

                        if (isCorrectOrder) {
                          _showCompleteDialog();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text('✗ क्रम सही नहीं है, पुनः प्रयास करें!'),
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
}

