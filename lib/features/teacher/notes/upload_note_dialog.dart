import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/note_model.dart';
import '../../../repositories/teacher_repository.dart';

class UploadNoteDialog extends StatefulWidget {
  final String lessonId;
  final int gradeClass;
  final String subject;
  final Function(TeacherNote) onUploaded;

  const UploadNoteDialog({
    super.key,
    required this.lessonId,
    required this.gradeClass,
    required this.subject,
    required this.onUploaded,
  });

  @override
  State<UploadNoteDialog> createState() => _UploadNoteDialogState();
}

class _UploadNoteDialogState extends State<UploadNoteDialog> {
  bool _isUploading = false;
  final String _selectedFileName = 'हस्तलिखित_पाठ_नोट्स.pdf';

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // Simulate OCR/Parsing

    final newNote = TeacherNote(
      id: 'note_${const Uuid().v4().substring(0, 8)}',
      lessonId: widget.lessonId,
      gradeClass: widget.gradeClass,
      subject: widget.subject,
      title: 'अपलोड किया गया पाठ: प्राथमिक शब्दावली',
      hindiContent: 'इस पाठ में बच्चों को परिवेश से संबंधित दैनिक वस्तुओं के नाम हिन्दी में सिखाए जाएंगे।',
      santaliContent: 'ᱱᱚᱣᱟ ᱯᱟᱴᱷ ᱨᱮ ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱥᱩᱨ-ᱥᱩᱯᱩᱨ ᱨᱮᱭᱟᱜ ᱡᱤᱱᱤᱥ ᱧᱩᱛᱩᱢ ᱪᱮᱫᱚᱜ ᱠᱚ᱾',
      santaliOlChiki: 'ᱥᱩᱨ-ᱥᱩᱯᱩᱨ ᱡᱤᱱᱤᱥ',
      author: 'Teacher (Uploaded Document)',
      isDraft: false,
      isPublished: true,
    );

    final repo = Provider.of<TeacherRepository>(context, listen: false);
    await repo.saveNote(newNote);

    if (mounted) {
      widget.onUploaded(newNote);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('✓ दस्तावेज़ सफलतापूर्वक लोड और पार्स हुआ'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.upload_file_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text(
            'नोट अपलोड करें',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'दस्तावेज़ या हस्तलिखित नोट्स स्कैन करके अपलोड करें (Upload PDF/Image note):',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '1.4 MB • PDF Document',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'टेक्स्ट निकाला जा रहा है (Parsing Text)...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('रद्द करें'),
        ),
        ElevatedButton(
          onPressed: _isUploading ? null : _handleUpload,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(110, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('अपलोड करें'),
        ),
      ],
    );
  }
}
