import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/auth_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/sync_service.dart';
import '../../../widgets/palash_card.dart';
import '../../../widgets/loading_dialog.dart';
import '../../../app/routes.dart';

class TeacherSettingsScreen extends StatefulWidget {
  const TeacherSettingsScreen({super.key});

  @override
  State<TeacherSettingsScreen> createState() => _TeacherSettingsScreenState();
}

class _TeacherSettingsScreenState extends State<TeacherSettingsScreen> {
  bool _enableOlChikiDefault = true;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('लॉगआउट (Logout)'),
        content: const Text('क्या आप शिक्षक खाते से बाहर निकलना चाहते हैं?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('लॉगआउट'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleSync() async {
    final syncSvc = Provider.of<SyncService>(context, listen: false);
    LoadingDialog.show(context, message: 'डेटाबेस सिंक हो रहा है...');
    await syncSvc.syncContent();
    if (mounted) {
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('✓ सभी ऑफलाइन डेटा सफलतापूर्वक सिंक हुआ'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final teacher = auth.currentUser ??
        TeacherUser(
          uid: 'teacher_01',
          email: 'rajesh.murmu@gov.jh.in',
          displayName: 'Shri Rajesh Murmu',
          schoolName: 'Govt. Primary Tribal Model School',
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'सेटिंग्स एवं प्रोफाइल / Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher Profile
            PalashCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      teacher.displayName[0],
                      style: const TextStyle(
                        fontSize: 26,
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          teacher.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          teacher.schoolName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // General Settings List
            const Text(
              'भाषा एवं लिपि प्राथमिकताएं (Linguistic Settings)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            PalashCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _enableOlChikiDefault,
                    activeColor: AppColors.secondary,
                    title: const Text(
                      'ओल चिकी लिपि प्रदर्शन (Ol Chiki Script Display)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'संताली पाठ के साथ ओल चिकी (ᱚᱞ ᱪᱤᱠᱤ) अक्षर प्रदर्शित करें',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onChanged: (val) {
                      setState(() => _enableOlChikiDefault = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Cloud & Offline Storage
            const Text(
              'डेटा एवं संग्रहण (Data & Storage)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            PalashCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
                    title: const Text('क्लाउड बैकअप सिंक (Sync Database)'),
                    subtitle: const Text('स्थानीय ऑफ़लाइन सामग्री को क्लाउड पर सिंक करें'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: _handleSync,
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const ListTile(
                    leading: Icon(Icons.storage_rounded, color: AppColors.secondary),
                    title: Text('स्थानीय डेटाबेस स्थिति (SQLite Database)'),
                    subtitle: Text('Drift / SQLite • 100% ऑफ़लाइन उपलब्ध'),
                    trailing: Text(
                      '4.2 MB',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'लॉगआउट करें (Logout)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
