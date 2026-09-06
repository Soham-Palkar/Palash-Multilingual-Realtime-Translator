import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/connection_status_badge.dart';
import '../../../widgets/palash_card.dart';
import '../../../app/routes.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F5E9), // Fresh leafy morning tint
              AppColors.background,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Student Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'वापस (Back to Welcome)',
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'विद्यार्थी शिक्षण केंद्र',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱥᱮᱪᱮᱫ (Student Learning Hub)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ConnectionStatusBadge(),
                  ],
                ),
              ),

              // Offline-Ready Student Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.offline_pin_rounded,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '१००% ऑफ़लाइन उपलब्ध (All Features Ready Offline)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          Text(
                            'इंटरनेट बंद होने पर भी सभी पाठ, खेल व कहानियाँ खेलें।',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 6 Big Colorful Student Learning Tiles Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: isTablet ? 3 : 2,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: isTablet ? 1.1 : 0.95,
                  children: [
                    // 1. Notes
                    _buildStudentTile(
                      context: context,
                      titleHindi: 'पाठ एवं नोट्स',
                      titleSantali: 'ᱯᱟᱴᱷ (Notes)',
                      subtitle: 'कक्षा १-५ के सचित्र पाठ',
                      icon: Icons.menu_book_rounded,
                      color: AppColors.moduleLanguage,
                      route: AppRoutes.studentNotes,
                    ),

                    // 2. Flashcards
                    _buildStudentTile(
                      context: context,
                      titleHindi: 'चित्र फ्लैशकार्ड्स',
                      titleSantali: 'ᱠᱟᱨᱰ (Flashcards)',
                      subtitle: 'भाषा, गणित व सामान्य ज्ञान',
                      icon: Icons.style_rounded,
                      color: AppColors.moduleMath,
                      route: AppRoutes.studentFlashcards,
                    ),

                    // 3. Worksheets
                    _buildStudentTile(
                      context: context,
                      titleHindi: 'अभ्यास पत्रक',
                      titleSantali: 'ᱠᱟᱹᱢᱤ ᱥᱟᱠᱟᱢ (Worksheets)',
                      subtitle: 'तुरंत सही-गलत जांच के साथ',
                      icon: Icons.quiz_rounded,
                      color: AppColors.moduleWorksheets,
                      route: AppRoutes.studentWorksheets,
                    ),

                    // 4. Games
                    _buildStudentTile(
                      context: context,
                      titleHindi: 'शैक्षणिक खेल',
                      titleSantali: 'ᱠᱷᱮᱞᱚᱸᱰ (Games)',
                      subtitle: 'शब्द मिलान, गिनती व मेमोरी',
                      icon: Icons.sports_esports_rounded,
                      color: AppColors.moduleGames,
                      route: AppRoutes.studentGames,
                    ),

                    // 5. Activities
                    _buildStudentTile(
                      context: context,
                      titleHindi: 'गतिविधियाँ',
                      titleSantali: 'ᱠᱟᱹᱢᱤᱦᱚᱨᱟ (Activities)',
                      subtitle: 'चित्र पहचान व रंग मिलान',
                      icon: Icons.extension_rounded,
                      color: AppColors.moduleActivities,
                      route: AppRoutes.studentActivities,
                    ),

                    // 6. Stories
                    _buildStudentTile(
                      context: context,
                      titleHindi: 'चित्र कहानियाँ',
                      titleSantali: 'ᱠᱟᱹᱦᱱᱤ (Stories)',
                      subtitle: 'प्रेरक लोक कथाएं',
                      icon: Icons.auto_stories_rounded,
                      color: AppColors.moduleStories,
                      route: AppRoutes.studentStories,
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

  Widget _buildStudentTile({
    required BuildContext context,
    required String titleHindi,
    required String titleSantali,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return PalashCard(
      backgroundColor: Colors.white,
      borderColor: color.withOpacity(0.3),
      borderRadius: 22,
      elevation: 2,
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleHindi,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titleSantali,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
