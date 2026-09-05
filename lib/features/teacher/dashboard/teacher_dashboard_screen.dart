import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';

import '../../../repositories/teacher_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_service.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/palash_card.dart';
import '../../../widgets/loading_dialog.dart';
import '../../../app/routes.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = Provider.of<TeacherRepository>(context, listen: false);
    final data = await repo.getTeacherStats();
    if (mounted) {
      setState(() {
        _stats = data;
      });
    }
  }

  Future<void> _handleSync() async {
    final syncSvc = Provider.of<SyncService>(context, listen: false);
    LoadingDialog.show(context, message: 'सिंक किया जा रहा है (Syncing with cloud)...');
    await syncSvc.syncContent();
    await _loadStats();
    if (mounted) {
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('✓ सामग्री सफलतापूर्वक सिंक हुई (Cloud sync complete)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final teacher = auth.currentUser;
    if (teacher == null) {
      // If not logged in, redirect to login screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.teacherLogin);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'शिक्षक डैशबोर्ड',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'क्लाउड सिंक (Sync)',
            icon: const Icon(Icons.sync_rounded),
            onPressed: _handleSync,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: ConnectionStatusBadge(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher Profile Banner Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        teacher.displayName.isNotEmpty
                            ? teacher.displayName[0]
                            : 'T',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacher.schoolName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '📍 ${teacher.district}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content Metrics / Stats Counters
              const Text(
                'सामग्री स्थिति अवलोकन (Content Overview)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'कुल पाठ\n(Notes)',
                      count: _stats['totalNotes'] ?? 7,
                      color: AppColors.primary,
                      icon: Icons.menu_book_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'ड्राफ्ट\n(Drafts)',
                      count: (_stats['draftNotes'] ?? 0) + (_stats['draftAI'] ?? 0),
                      color: AppColors.tertiary,
                      icon: Icons.edit_note_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'प्रकाशित\n(Published)',
                      count: _stats['publishedNotes'] ?? 7,
                      color: AppColors.secondary,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6 Main Modules Header
              const Text(
                'शिक्षक मॉड्यूल (Main Modules)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Grid of 6 Main Modules
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _buildModuleCard(
                    title: 'पाठ्यक्रम और नोट्स',
                    subtitle: 'Curriculum & Notes',
                    icon: Icons.auto_stories_rounded,
                    color: AppColors.moduleLanguage,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teacherCurriculum);
                    },
                  ),
                  _buildModuleCard(
                    title: 'लाइव अनुवाद',
                    subtitle: 'Live Translation',
                    icon: Icons.g_translate_rounded,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teacherTranslation);
                    },
                  ),
                  _buildModuleCard(
                    title: 'AI सामग्री जनरेटर',
                    subtitle: 'AI Content Generation',
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.moduleWorksheets,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teacherAIGenerator);
                    },
                  ),
                  _buildModuleCard(
                    title: 'फ्लैशकार्ड स्टूडियो',
                    subtitle: 'Flashcards Studio',
                    icon: Icons.style_rounded,
                    color: AppColors.moduleMath,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teacherFlashcards);
                    },
                  ),
                  _buildModuleCard(
                    title: 'सामग्री समीक्षा',
                    subtitle: 'Content Review',
                    icon: Icons.rate_review_rounded,
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teacherReview);
                    },
                  ),
                  _buildModuleCard(
                    title: 'सेटिंग्स व प्रोफाइल',
                    subtitle: 'Settings & Profile',
                    icon: Icons.settings_suggest_rounded,
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.teacherSettings);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Action Bar: Send Note to AI
              PalashCard(
                backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
                borderColor: AppColors.primary.withOpacity(0.3),
                padding: const EdgeInsets.all(16),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.teacherAIGenerator);
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'त्वरित AI सामग्री निर्माण (Quick AI Studio)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'हिन्दी पाठ से संताली अनुवाद, फ्लैशकार्ड व अभ्यास पत्रक बनाएं',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PalashCard(
      onTap: onTap,
      elevation: 1,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
