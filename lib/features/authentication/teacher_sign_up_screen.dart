import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/connection_status_badge.dart';
import '../../widgets/loading_dialog.dart';
import '../../app/routes.dart';

class TeacherSignUpScreen extends StatefulWidget {
  const TeacherSignUpScreen({super.key});

  @override
  State<TeacherSignUpScreen> createState() => _TeacherSignUpScreenState();
}

class _TeacherSignUpScreenState extends State<TeacherSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  final _districtController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _districtController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingDialog.show(
      context,
      message: 'शिक्षक खाता बनाया जा रहा है (Creating Account)...',
    );
    final auth = Provider.of<AuthService>(context, listen: false);

    try {
      await auth.createTeacherAccount(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        school: _schoolController.text.trim(),
        district: _districtController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      LoadingDialog.hide(context);
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.teacherDashboard,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'शिक्षक पंजीकरण / Teacher Sign Up',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ConnectionStatusBadge(showLabel: false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header description banner matching TeacherLoginScreen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'नया शिक्षक पंजीकरण (Teacher Registration)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'पाठ्यक्रम, AI सामग्री एवं अनुवाद प्रबंधन हेतु',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Full Name Input
              const Text(
                'पूरा नाम (Full Name)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'उदा. Mahavir Rawal',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'कृपया पूरा नाम दर्ज करें (Please enter full name)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Email Input
              const Text(
                'ईमेल पता (Email)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'teacher@palash.edu.in',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'कृपया ईमेल दर्ज करें (Please enter email)';
                  }
                  final emailRegExp = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegExp.hasMatch(val.trim())) {
                    return 'कृपया वैध ईमेल दर्ज करें (Please enter valid email)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // School Name Input
              const Text(
                'विद्यालय का नाम (School Name)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _schoolController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'उदा. Govt. Primary Tribal Model School',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'कृपया विद्यालय का नाम दर्ज करें (Please enter school name)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // District Input
              const Text(
                'जिला एवं राज्य (District & State)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _districtController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'उदा. Dumka, Jharkhand',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'कृपया जिला दर्ज करें (Please enter district)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Password Input
              const Text(
                'पासवर्ड (Password)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'कम से कम 6 अक्षर ••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'कृपया पासवर्ड दर्ज करें (Please enter password)';
                  }
                  if (val.length < 6) {
                    return 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए (Min 6 chars)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Confirm Password Input
              const Text(
                'पासवर्ड की पुष्टि करें (Confirm Password)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'कृपया पासवर्ड की पुष्टि करें (Please confirm password)';
                  }
                  if (val != _passwordController.text) {
                    return 'पासवर्ड मेल नहीं खाते (Passwords do not match)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _handleSignUp,
                child: const Text('खाता बनाएं / Create Teacher Account'),
              ),

              const SizedBox(height: 20),

              // Already have an account? Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'पहले से खाता है? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.teacherLogin,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'लॉगिन करें (Sign In)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
