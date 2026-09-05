import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/note_model.dart';
import '../../../repositories/teacher_repository.dart';
import '../../../services/ai_content_service.dart';
import '../../../widgets/loading_dialog.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class AIGeneratorScreen extends StatefulWidget {
  final TeacherNote? preselectedNote;

  const AIGeneratorScreen({super.key, this.preselectedNote});

  @override
  State<AIGeneratorScreen> createState() => _AIGeneratorScreenState();
}

class _AIGeneratorScreenState extends State<AIGeneratorScreen> {
  TeacherNote? _selectedNote;
  List<TeacherNote> _allNotes = [];
  bool _isLoadingNotes = true;

  // 6 Generation Options Checkboxes
  final Map<String, bool> _options = {
    'Lesson Explanation': true,
    'Santali Translation': true,
    'Flashcards': true,
    'Worksheet': true,
    'Practice Questions': true,
    'Activities': true,
  };

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final repo = Provider.of<TeacherRepository>(context, listen: false);
    final notes = await repo.getAllNotes();
    if (mounted) {
      setState(() {
        _allNotes = notes;
        _isLoadingNotes = false;
        if (widget.preselectedNote != null) {
          _selectedNote = widget.preselectedNote;
        } else if (_allNotes.isNotEmpty) {
          _selectedNote = _allNotes.first;
        }
      });
    }
  }

  Future<void> _generateContent() async {
    if (_selectedNote == null) return;

    final selectedKeys = _options.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('कृपया कम से कम एक विकल्प चुनें (Select at least one option)'),
        ),
      );
      return;
    }

    LoadingDialog.show(context, message: AppStrings.generatingAI);

    try {
      final aiService = Provider.of<AIContentService>(context, listen: false);
      final generated = await aiService.generateContent(
        note: _selectedNote!,
        selectedOptions: selectedKeys,
      );

      final repo = Provider.of<TeacherRepository>(context, listen: false);
      await repo.saveAIContent(generated);

      if (!mounted) return;
      LoadingDialog.hide(context);

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.teacherDraftReview,
        arguments: {
          'aiContent': generated,
          'note': _selectedNote,
        },
      );
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('सामग्री निर्माण में त्रुटि: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.moduleWorksheets),
            SizedBox(width: 8),
            Text(
              'AI सामग्री जनरेटर',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      body: _isLoadingNotes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.moduleWorksheets.withOpacity(0.12),
                          AppColors.primaryContainer.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.moduleWorksheets.withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: AppColors.moduleWorksheets,
                          size: 32,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'मातृभाषा आधारित AI सामग्री निर्माण',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'नोट्स चुनें और प्राथमिक बच्चों के लिए द्विभाषी फ्लैशकार्ड, प्रश्न व गतिविधियाँ उत्पन्न करें।',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Select Note Section
                  const Text(
                    '१. शिक्षक नोट चुनें (Select Note):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_allNotes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('पहले पाठ्यक्रम से एक नोट जोड़ें।'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<TeacherNote>(
                          isExpanded: true,
                          value: _selectedNote,
                          items: _allNotes.map((note) {
                            return DropdownMenuItem<TeacherNote>(
                              value: note,
                              child: Text(
                                'कक्षा ${note.gradeClass} • ${note.subject} : ${note.title}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedNote = val);
                          },
                        ),
                      ),
                    ),

                  if (_selectedNote != null) ...[
                    const SizedBox(height: 12),
                    PalashCard(
                      backgroundColor: AppColors.surfaceVariant.withOpacity(0.6),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'चयनित नोट सामग्री (Selected Note Content):',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedNote!.hindiContent,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 2. Generation Options Checkboxes
                  const Text(
                    '२. क्या सामग्री उत्पन्न करनी है? (Select Options):',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: _options.keys.map((key) {
                        String hindiLabel = key;
                        IconData icon = Icons.check_box_outlined;

                        if (key == 'Lesson Explanation') {
                          hindiLabel = 'पाठ्य व्याख्या (Lesson Explanation)';
                          icon = Icons.menu_book_rounded;
                        } else if (key == 'Santali Translation') {
                          hindiLabel = 'संताली अनुवाद (Santali Translation)';
                          icon = Icons.g_translate_rounded;
                        } else if (key == 'Flashcards') {
                          hindiLabel = 'चित्र फ्लैशकार्ड (Bilingual Flashcards)';
                          icon = Icons.style_rounded;
                        } else if (key == 'Worksheet') {
                          hindiLabel = 'अभ्यास पत्रक (Worksheet)';
                          icon = Icons.assignment_rounded;
                        } else if (key == 'Practice Questions') {
                          hindiLabel = 'अभ्यास प्रश्न (Practice Questions)';
                          icon = Icons.quiz_rounded;
                        } else if (key == 'Activities') {
                          hindiLabel = 'कक्षा गतिविधियाँ (Activities)';
                          icon = Icons.extension_rounded;
                        }

                        return CheckboxListTile(
                          value: _options[key],
                          activeColor: AppColors.moduleWorksheets,
                          secondary: Icon(icon, color: AppColors.moduleWorksheets),
                          title: Text(
                            hindiLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _options[key] = val ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.moduleWorksheets,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text(
                        'AI सामग्री जनरेट करें (Generate Learning Content)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Center(
                    child: Text(
                      'उत्पन्न सामग्री पहले ड्राफ्ट (Draft) के रूप में खुलेगी और समीक्षा के बाद ही प्रकाशित होगी।',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
