import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/curriculum_model.dart';
import '../../../models/note_model.dart';
import '../../../repositories/teacher_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/palash_card.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../app/routes.dart';
import '../notes/upload_note_dialog.dart';

class LessonDetailScreen extends StatefulWidget {
  final CurriculumLesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  List<TeacherNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _notes = widget.lesson.notes;
  }

  void _handleUploadNote() {
    showDialog(
      context: context,
      builder: (ctx) => UploadNoteDialog(
        lessonId: widget.lesson.id,
        gradeClass: widget.lesson.gradeClass,
        subject: widget.lesson.subject,
        onUploaded: (newNote) {
          setState(() {
            _notes.insert(0, newNote);
          });
        },
      ),
    );
  }

  Future<void> _handleDeleteNote(TeacherNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('नोट हटाएं? (Delete Note)'),
        content: Text('क्या आप "${note.title}" नोट को हटाना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = Provider.of<TeacherRepository>(context, listen: false);
      await repo.deleteNote(note.id);
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('नोट हटा दिया गया')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'कक्षा ${widget.lesson.gradeClass} • ${widget.lesson.subject}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'नोट अपलोड करें (Upload Note)',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: _handleUploadNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson Banner Card
            PalashCard(
              backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
              borderColor: AppColors.primary.withOpacity(0.3),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BilingualText(
                    hindi: widget.lesson.titleHindi,
                    santali: widget.lesson.titleSantali,
                    hindiFontSize: 20,
                    santaliFontSize: 16,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.lesson.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.teacherAddNote,
                            arguments: {
                              'lessonId': widget.lesson.id,
                              'gradeClass': widget.lesson.gradeClass,
                              'subject': widget.lesson.subject,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('नया नोट'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _handleUploadNote,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(130, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: const Text('अपलोड नोट'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'शिक्षक नोट्स (${_notes.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'हिन्दी & संताली पाठ्य सामग्री',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_notes.isEmpty)
              const EmptyStateView(
                title: 'कोई नोट नहीं मिला',
                subtitle: 'इस पाठ के लिए प्रथम शिक्षक नोट जोड़ें या अपलोड करें।',
                icon: Icons.note_add_rounded,
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PalashCard(
                      elevation: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.teacherAddNote,
                                      arguments: note,
                                    );
                                  } else if (val == 'delete') {
                                    _handleDeleteNote(note);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('संपादित करें (Edit)'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded,
                                            size: 18, color: AppColors.error),
                                        SizedBox(width: 8),
                                        Text('हटाएं (Delete)',
                                            style:
                                                TextStyle(color: AppColors.error)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Hindi Content
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'हिन्दी पाठ्य सामग्री (Hindi Content):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.hindiContent,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Santali Content
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱚᱨᱡᱚᱢᱟ (Santali Translation):',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.santaliContent,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.secondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Send to AI Content Generation Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.teacherAIGenerator,
                                  arguments: note,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.moduleWorksheets,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                              label: const Text(
                                'AI सामग्री बनाएं (Generate Learning Content)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
