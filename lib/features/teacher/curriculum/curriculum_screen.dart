import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/curriculum_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/palash_card.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../app/routes.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  int _selectedClass = 1;
  String _selectedSubject = 'Language';
  List<CurriculumLesson> _lessons = [];
  bool _isLoading = true;

  final List<String> _subjects = [
    'Language',
    'Mathematics',
    'EVS / General Knowledge',
  ];

  @override
  void initState() {
    super.initState();
    _loadLessons();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'पाठ्यक्रम और नोट्स / Curriculum',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(showLabel: false),
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Filter Selector (Class 1 to 5)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'कक्षा चुनें (Select Class):',
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
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Class $grade',
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
                      if (subj == 'EVS / General Knowledge') subjHindi = 'पर्यावरण (EVS)';

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          showCheckmark: false,
                          label: Text('$subjHindi ($subj)'),
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.secondary : AppColors.border,
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
                    ? EmptyStateView(
                        title: 'कोई पाठ उपलब्ध नहीं है',
                        subtitle: 'कक्षा $_selectedClass - $_selectedSubject के लिए नया पाठ जोड़ें।',
                        icon: Icons.auto_stories_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lessons.length,
                        itemBuilder: (context, index) {
                          final lesson = _lessons[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PalashCard(
                              elevation: 1,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.teacherLessonDetail,
                                  arguments: lesson,
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.menu_book_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: BilingualText(
                                          hindi: lesson.titleHindi,
                                          santali: lesson.titleSantali,
                                          hindiFontSize: 16,
                                          santaliFontSize: 14,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    lesson.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryContainer,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${lesson.notes.length} शिक्षण नोट्स',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.teacherLessonDetail,
                                            arguments: lesson,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'नोट्स देखें / जोड़ें',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.teacherAddNote,
            arguments: {
              'gradeClass': _selectedClass,
              'subject': _selectedSubject,
            },
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('नया नोट जोड़ें'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
