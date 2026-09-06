import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/connection_status_badge.dart';
import '../../widgets/palash_card.dart';
import '../../app/routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              Color(0xFFFFF3E0), // Warm sunrise tint
              AppColors.background,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                // Top Bar with Connectivity Badge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_florist_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mother Tongue Pedagogy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const ConnectionStatusBadge(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // PALASH Hero Branding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Brand Icon / Emblem
                      Container(
                        width: isTablet ? 120 : 96,
                        height: isTablet ? 120 : 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_florist_rounded,
                            size: 54,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // App Title
                      const Text(
                        AppStrings.appName,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Tagline Hindi
                      const Text(
                        AppStrings.appTaglineHindi,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Tagline Santali & English
                      const Text(
                        '${AppStrings.appSubtitleSantali} • ${AppStrings.appTaglineEnglish}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Vernacular Subtitle Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'हिन्दी & ᱥᱟᱱᱛᱟᱲᱤ (Santali) Primary Education',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Two Large Role Buttons (Teacher & Student)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 24),
                  child: Column(
                    children: [
                      // Student Button (Primary, Colorful, Direct Entry)
                      PalashCard(
                        backgroundColor: AppColors.secondary,
                        borderColor: Colors.transparent,
                        borderRadius: 22,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        elevation: 3,
                        onTap: () {
                          // Student flow has NO LOGIN - direct entry!
                          Navigator.pushNamed(context, AppRoutes.studentHome);
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'विद्यार्थी / Student',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'बिना लॉगिन सीधे सीखें • 100% Offline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Teacher Button (Professional & Accessible)
                      PalashCard(
                        backgroundColor: Colors.white,
                        borderColor: AppColors.primary,
                        borderRadius: 22,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        elevation: 1,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.teacherLogin);
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                size: 30,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'शिक्षक / Teacher',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'पाठ्यक्रम, AI सामग्री एवं अनुवाद स्टूडियो',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom Accessibility & Offline info
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.offline_pin_rounded,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'पूर्णतः ऑफ़लाइन सक्षम (Fully Offline Functional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
