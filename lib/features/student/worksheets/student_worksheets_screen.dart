import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/worksheet_model.dart';
import '../../../repositories/content_repository.dart';
import '../../../widgets/bilingual_text.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class StudentWorksheetsScreen extends StatefulWidget {
  const StudentWorksheetsScreen({super.key});

  @override
  State<StudentWorksheetsScreen> createState() => _StudentWorksheetsScreenState();
}

class _StudentWorksheetsScreenState extends State<StudentWorksheetsScreen> {
  List<WorksheetItem> _worksheets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorksheets();
  }

  Future<void> _loadWorksheets() async {
    final repo = Provider.of<ContentRepository>(context, listen: false);
    final list = await repo.getWorksheets();
    if (mounted) {
      setState(() {
        _worksheets = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'अभ्यास पत्रक / Worksheets',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _worksheets.isEmpty
              ? const EmptyStateView(
                  title: 'कोई अभ्यास पत्रक नहीं मिला',
                  subtitle: 'अभ्यास पत्रक शीघ्र लोड होंगे।',
                  icon: Icons.quiz_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _worksheets.length,
                  itemBuilder: (context, index) {
                    final ws = _worksheets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PalashCard(
                        elevation: 2,
                        borderColor: AppColors.moduleWorksheets.withOpacity(0.3),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.studentWorksheetPlayer,
                            arguments: ws,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.moduleWorksheets.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: AppColors.moduleWorksheets,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'कक्षा ${ws.gradeClass} • ${ws.subject}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  BilingualText(
                                    hindi: ws.titleHindi,
                                    santali: ws.titleSantali,
                                    hindiFontSize: 15,
                                    santaliFontSize: 13,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${ws.questions.length} सचित्र प्रश्न • तुरंत जांच',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
