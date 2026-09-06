import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ai_content_model.dart';
import '../../../models/note_model.dart';
import '../../../repositories/teacher_repository.dart';
import '../../../services/ai_content_service.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/loading_dialog.dart';
import '../../../widgets/palash_card.dart';
import '../../../widgets/palash_asset_image.dart';

class DraftReviewScreen extends StatefulWidget {
  final AIGeneratedContent aiContent;
  final TeacherNote? note;

  const DraftReviewScreen({
    super.key,
    required this.aiContent,
    this.note,
  });

  @override
  State<DraftReviewScreen> createState() => _DraftReviewScreenState();
}

class _DraftReviewScreenState extends State<DraftReviewScreen> {
  late AIGeneratedContent _content;
  late TextEditingController _explanationController;
  late TextEditingController _translationController;
  bool _isEditingExplanation = false;
  bool _isEditingTranslation = false;

  @override
  void initState() {
    super.initState();
    _content = widget.aiContent;
    _explanationController =
        TextEditingController(text: _content.explanationHindi);
    _translationController =
        TextEditingController(text: _content.translationSantali);
  }

  @override
  void dispose() {
    _explanationController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegenerate() async {
    if (widget.note == null) return;
    LoadingDialog.show(context, message: 'पुनः सामग्री तैयार हो रही है (Regenerating)...');
    final aiService = Provider.of<AIContentService>(context, listen: false);

    try {
      final updated = await aiService.regenerateContent(
        previousContent: _content,
        note: widget.note!,
        sectionToRegenerate: 'all',
      );
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() {
        _content = updated;
        _explanationController.text = updated.explanationHindi;
        _translationController.text = updated.translationSantali;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('✓ सामग्री पुनः उत्पन्न हुई (Content regenerated)'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('त्रुटि: $e')),
      );
    }
  }

  

  Future<void> _handleApprove() async {
    LoadingDialog.show(context, message: 'नोट स्वीकृत हो रहा है...');
    final repo = Provider.of<TeacherRepository>(context, listen: false);
    if (widget.note != null) {
      await repo.approveNote(widget.note!);
      setState(() {
        _content.state = ContentState.approved;
      });
    } else {
      await repo.approveAIContent(_content.id);
      setState(() {
        _content.state = ContentState.approved;
      });
    }
    if (!mounted) return;
    LoadingDialog.hide(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.info,
        content: Text('✓ सामग्री स्वीकृत हुई (Content approved)'),
      ),
    );
  }

  Future<void> _handlePublish() async {
    LoadingDialog.show(context, message: 'सामग्री प्रकाशित हो रही है...');
    final repo = Provider.of<TeacherRepository>(context, listen: false);
    if (widget.note != null) {
      await repo.publishNote(widget.note!);
      setState(() {
        _content.state = ContentState.published;
      });
    } else {
      await repo.publishAIContent(_content);
      setState(() {
        _content.state = ContentState.published;
      });
    }
    if (!mounted) return;
    LoadingDialog.hide(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 28),
            SizedBox(width: 10),
            Text('सफलतापूर्वक प्रकाशित!'),
          ],
        ),
        content: const Text(
          'यह सामग्री अब स्थानीय डेटाबेस में सुरक्षित हो गई है और विद्यार्थी इसे ऑफ़लाइन सीख सकते हैं।',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('डैशबोर्ड पर जाएँ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String stateLabel = 'ड्राफ्ट (DRAFT)';
    Color stateColor = AppColors.tertiary;

    if (_content.state == ContentState.approved) {
      stateLabel = 'स्वीकृत (APPROVED)';
      stateColor = AppColors.info;
    } else if (_content.state == ContentState.published) {
      stateLabel = 'प्रकाशित (PUBLISHED)';
      stateColor = AppColors.secondary;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'समीक्षा: ${_content.noteTitle}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: stateColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stateColor),
            ),
            child: Center(
              child: Text(
                stateLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: stateColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Info Card
            PalashCard(
              backgroundColor: stateColor.withOpacity(0.08),
              borderColor: stateColor.withOpacity(0.3),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _content.state == ContentState.draft
                        ? Icons.edit_note_rounded
                        : Icons.verified_rounded,
                    color: stateColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'कार्यप्रवाह स्थिति (Workflow State): $stateLabel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: stateColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Teacher Notes → AI Generation → Draft → Teacher Review → Edit / Regenerate → Approve → Publish',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 1. Lesson Explanation Section
            _buildSectionHeader('१. पाठ्य व्याख्या (Lesson Explanation)'),
            const SizedBox(height: 8),
            PalashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditingExplanation) ...[
                    TextFormField(
                      controller: _explanationController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'हिन्दी व्याख्या संपादित करें',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _content = _content.copyWith(
                            explanationHindi: _explanationController.text,
                          );
                          _isEditingExplanation = false;
                        });
                      },
                      child: const Text('सेव करें (Save)'),
                    ),
                  ] else ...[
                    Text(
                      _content.explanationHindi,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _content.explanationSantali,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _isEditingExplanation = true),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('संपादित करें (Edit)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Santali Translation Section
            _buildSectionHeader('२. संताली अनुवाद (Santali Translation)'),
            const SizedBox(height: 8),
            PalashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditingTranslation) ...[
                    TextFormField(
                      controller: _translationController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'संताली अनुवाद संपादित करें',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _content = _content.copyWith(
                            translationSantali: _translationController.text,
                          );
                          _isEditingTranslation = false;
                        });
                      },
                      child: const Text('सेव करें (Save)'),
                    ),
                  ] else ...[
                    Text(
                      _content.translationSantali,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _isEditingTranslation = true),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('संपादित करें (Edit)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. AI Generated Flashcards
            if (_content.flashcards.isNotEmpty) ...[
              _buildSectionHeader('३. AI जनरेटेड फ्लैशकार्ड्स (AI Flashcards)'),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _content.flashcards.length,
                itemBuilder: (context, index) {
                  final fc = _content.flashcards[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PalashCard(
                      child: Row(
                        children: [
                          PalashAssetImage(
                            imagePath: fc.image,
                            width: 60,
                            height: 60,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: BilingualText(
                              hindi: fc.hindi,
                              santali: fc.santali,
                              santaliOlChiki: fc.santaliOlChiki,
                              hindiFontSize: 15,
                              santaliFontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            // 4. Practice Questions Section
            if (_content.practiceQuestions.isNotEmpty) ...[
              _buildSectionHeader('४. अभ्यास प्रश्न (Practice Questions)'),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _content.practiceQuestions.length,
                itemBuilder: (context, index) {
                  final q = _content.practiceQuestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PalashCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BilingualText(
                            hindi: 'प्र ${index + 1}: ${q.questionHindi}',
                            santali: q.questionSantali,
                            hindiFontSize: 15,
                            santaliFontSize: 13,
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(q.optionsHindi.length, (optIdx) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '○ ${q.optionsHindi[optIdx]} (${q.optionsSantali[optIdx]})',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            // 5. Activities Section
            if (_content.activities.isNotEmpty) ...[
              _buildSectionHeader('५. कक्षा गतिविधियाँ (Activities)'),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _content.activities.length,
                itemBuilder: (context, index) {
                  final a = _content.activities[index];
                  return PalashCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BilingualText(
                          hindi: a.titleHindi,
                          santali: a.titleSantali,
                          hindiFontSize: 15,
                          santaliFontSize: 13,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.descriptionHindi,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons: Regenerate, Approve, Publish
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleRegenerate,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('पुनः बनाएं (Regenerate)'),
                  ),
                ),
                const SizedBox(width: 12),
                if (_content.state == ContentState.draft)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('स्वीकृत करें (Approve)'),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handlePublish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                      ),
                      icon: const Icon(Icons.publish_rounded),
                      label: const Text('प्रकाशित करें (Publish)'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
