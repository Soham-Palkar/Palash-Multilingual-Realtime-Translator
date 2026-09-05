import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/note_model.dart';
import '../../../repositories/teacher_repository.dart';

class AddEditNoteScreen extends StatefulWidget {
  final dynamic initialData; // TeacherNote or Map<String, dynamic>

  const AddEditNoteScreen({super.key, this.initialData});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _hindiController;
  late TextEditingController _santaliController;
  late TextEditingController _olChikiController;

  int _gradeClass = 1;
  String _subject = 'Language';
  String _lessonId = 'curr_c1_lang_01';
  bool _isEditing = false;
  TeacherNote? _existingNote;

  @override
  void initState() {
    super.initState();
    if (widget.initialData is TeacherNote) {
      _isEditing = true;
      _existingNote = widget.initialData as TeacherNote;
      _gradeClass = _existingNote!.gradeClass;
      _subject = _existingNote!.subject;
      _lessonId = _existingNote!.lessonId;
      _titleController = TextEditingController(text: _existingNote!.title);
      _hindiController = TextEditingController(text: _existingNote!.hindiContent);
      _santaliController = TextEditingController(text: _existingNote!.santaliContent);
      _olChikiController = TextEditingController(text: _existingNote!.santaliOlChiki ?? '');
    } else if (widget.initialData is Map) {
      final map = widget.initialData as Map;
      _gradeClass = map['gradeClass'] ?? 1;
      _subject = map['subject'] ?? 'Language';
      _lessonId = map['lessonId'] ?? 'curr_c1_lang_01';
      _titleController = TextEditingController();
      _hindiController = TextEditingController();
      _santaliController = TextEditingController();
      _olChikiController = TextEditingController();
    } else {
      _titleController = TextEditingController();
      _hindiController = TextEditingController();
      _santaliController = TextEditingController();
      _olChikiController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hindiController.dispose();
    _santaliController.dispose();
    _olChikiController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = Provider.of<TeacherRepository>(context, listen: false);

    if (_isEditing && _existingNote != null) {
      final updated = _existingNote!.copyWith(
        title: _titleController.text.trim(),
        hindiContent: _hindiController.text.trim(),
        santaliContent: _santaliController.text.trim(),
        santaliOlChiki: _olChikiController.text.trim(),
      );
      await repo.updateNote(updated);
    } else {
      final newNote = TeacherNote(
        id: 'note_${const Uuid().v4().substring(0, 8)}',
        lessonId: _lessonId,
        gradeClass: _gradeClass,
        subject: _subject,
        title: _titleController.text.trim(),
        hindiContent: _hindiController.text.trim(),
        santaliContent: _santaliController.text.trim().isNotEmpty
            ? _santaliController.text.trim()
            : '<!-- TODO: LINGUIST_VERIFICATION -->',
        santaliOlChiki: _olChikiController.text.trim(),
        author: 'Teacher',
        isDraft: false,
        isPublished: true,
      );
      await repo.saveNote(newNote);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text(_isEditing ? 'नोट अपडेट हो गया' : 'नया नोट सुरक्षित हुआ'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'नोट संपादित करें (Edit Note)' : 'नया शिक्षण नोट (Add Note)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class & Subject Header Badges
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'कक्षा $_gradeClass',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'नोट शीर्षक (Title)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'उदा. वर्णमाला के स्वर / संख्या ज्ञान',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'शीर्षक आवश्यक है';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Hindi Content
              const Text(
                'हिन्दी पाठ्य सामग्री (Hindi Content)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _hindiController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'शिक्षक व्याख्या, उदाहरण व महत्वपूर्ण बिन्दु लिखें...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'हिन्दी सामग्री आवश्यक है';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Santali Content (Optional / Auto translated via AI)
              const Row(
                children: [
                  Text(
                    'ᱥᱟᱱᱛᱟᱲᱤ ᱛᱚᱨᱡᱚᱢᱟ (Santali Translation)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '(वैकल्पिक / AI द्वारा तैयार की जा सकती है)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _santaliController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'संताली भाषा अनुवाद (यदि उपलब्ध हो)...',
                ),
              ),

              const SizedBox(height: 18),

              // Ol Chiki script input (Optional)
              const Text(
                'ᱚᱞ ᱪᱤᱠᱤ (Ol Chiki Text - Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _olChikiController,
                decoration: const InputDecoration(
                  hintText: 'ᱚᱞ ᱪᱤᱠᱤ ᱪᱤᱠᱤ ᱛᱮ ᱚᱞ...',
                ),
              ),

              const SizedBox(height: 28),

              // Save Button
              ElevatedButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isEditing ? 'अपडेट करें (Update)' : 'सुरक्षित करें (Save Note)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
