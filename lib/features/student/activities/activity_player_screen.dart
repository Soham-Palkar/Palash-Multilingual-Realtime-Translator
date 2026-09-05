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
  int? _selectedOption;

  void _showCompleteDialog() {
    showDialog(
      context: context,
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

  Widget _buildMatchConcepts() {
    final pairs = (widget.activity.rawData['pairs'] as List? ?? []);

    return Column(
      children: [
        ...pairs.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PalashCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['objectHindi'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        p['objectSantali'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppColors.secondary),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${p['colorHindi']} (${p['colorSantali']})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _showCompleteDialog,
          child: const Text('गतिविधि पूरी हुई (Complete)'),
        ),
      ],
    );
  }

  Widget _buildArrangeObjects() {
    final steps = (widget.activity.rawData['steps'] as List? ?? []);

    return Column(
      children: [
        ...steps.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PalashCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.moduleActivities,
                    child: Text(
                      '${s['rank']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['nameHindi'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          s['nameSantali'] ?? '',
                          style: const TextStyle(fontSize: 13, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _showCompleteDialog,
          child: const Text('गतिविधि पूरी हुई (Complete)'),
        ),
      ],
    );
  }
}
