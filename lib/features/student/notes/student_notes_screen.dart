import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/note_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/curriculum_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class StudentNotesScreen extends StatefulWidget {
  const StudentNotesScreen({super.key});

  @override
  State<StudentNotesScreen> createState() => _StudentNotesScreenState();
}

class _StudentNotesScreenState extends State<StudentNotesScreen> {
  int _selectedClass = 1;
  String _selectedSubject = 'Language';
  List<CurriculumLesson> _lessons = [];
  List<TeacherNote> _notes = [];
  bool _isLoading = true;
  bool _isNotesLoading = false;


  final List<String> _subjects = [
    'Language',
    'Mathematics',
    'EVS / General Knowledge',
  ];

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _loadNotes();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    final repo = Provider.of<ContentRepository>(context, listen: false);
    final list = await repo.getCurriculumByClassAndSubject(
      _selectedClass,
      _selectedSubject,
    );
    if (mounted) {
      setState(() {
        _lessons = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _isNotesLoading = true);
    final repo = Provider.of<ContentRepository>(context, listen: false);
    final list = await repo.getPublishedNotes();
    if (mounted) {
      setState(() {
        _notes = list;
        _isNotesLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'पाठ और नोट्स / Notes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Filter Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'अपनी कक्षा चुनें (Select Class):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final grade = index + 1;
                    final isSelected = _selectedClass == grade;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedClass = grade);
                            _loadLessons();
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'कक्षा $grade',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Subject Segmented Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _subjects.map((subj) {
                      final isSelected = _selectedSubject == subj;
                      String subjHindi = 'भाषा';
                      if (subj == 'Mathematics') subjHindi = 'गणित';
                      if (subj == 'EVS / General Knowledge') subjHindi = 'पर्यावरण';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          label: Text('$subjHindi ($subj)'),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.moduleLanguage,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.moduleLanguage : AppColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSubject = subj);
                              _loadLessons();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Lessons List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _lessons.isEmpty
                    ? const EmptyStateView(
                        title: 'कोई पाठ उपलब्ध नहीं है',
                        subtitle: 'इस कक्षा व विषय के लिए पाठ शीघ्र उपलब्ध होंगे।',
                        icon: Icons.menu_book_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PalashCard(
                              elevation: 2,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.studentLessonView,
                                  arguments: lesson,
                                );
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        BilingualText(
                                          hindi: lesson.titleHindi,
                                          santali: lesson.titleSantali,
                                          hindiFontSize: 16,
                                          santaliFontSize: 14,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lesson.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppColors.textMuted,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Published Student Notes List
          Expanded(
            child: _isNotesLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const EmptyStateView(
                        title: 'कोई नोट उपलब्ध नहीं है',
                        subtitle: 'इस कक्षा के लिये प्रकाशित नोट उपलब्ध नहीं हैं।',
                        icon: Icons.note_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length,
                        itemBuilder: (context, idx) {
                          final note = _notes[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PalashCard(
                              elevation: 2,
                              onTap: () {
                                // Add navigation to note view if exists, else no-op
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
