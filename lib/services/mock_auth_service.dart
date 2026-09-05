import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import 'auth_service.dart';

/// Mock Implementation of AuthService
/// Simulates persistent teacher authentication locally.
class MockAuthService implements AuthService {
  static const String _keyTeacherLoggedIn = 'palash_teacher_logged_in';
  final _controller = StreamController<TeacherUser?>.broadcast();
  TeacherUser? _currentUser;

  MockAuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyTeacherLoggedIn) ?? false;
    if (isLoggedIn) {
      _currentUser = TeacherUser(
        uid: 'teacher_jh_dumka_01',
        email: 'rajesh.murmu@gov.jh.in',
        displayName: 'Shri Rajesh Murmu',
        schoolName: 'Govt. Primary Tribal Model School, Dumka',
        district: 'Dumka, Jharkhand',
      );
    }
    _controller.add(_currentUser);
  }

  @override
  Stream<TeacherUser?> get authStateChanges => _controller.stream;

  @override
  TeacherUser? get currentUser => _currentUser;

  @override
  Future<TeacherUser> signInWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate auth latency
    if (email.trim().isEmpty || password.length < 4) {
      throw Exception('कृपया वैध ईमेल और पासवर्ड दर्ज करें (Invalid credentials).');
    }

    _currentUser = TeacherUser(
      uid: 'teacher_jh_dumka_01',
      email: email.trim(),
      displayName: 'Shri Rajesh Murmu',
      schoolName: 'Govt. Primary Tribal Model School, Dumka',
      district: 'Dumka, Jharkhand',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTeacherLoggedIn, true);

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<TeacherUser> createTeacherAccount({
    required String name,
    required String email,
    required String school,
    required String district,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (email.trim().isEmpty || password.length < 6) {
      throw Exception('कृपया वैध ईमेल और कम से कम 6 अक्षरों का पासवर्ड दर्ज करें।');
    }

    _currentUser = TeacherUser(
      uid: 'teacher_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: name.trim(),
      schoolName: school.trim(),
      district: district.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTeacherLoggedIn, true);

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<TeacherUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 700));
    _currentUser = TeacherUser(
      uid: 'teacher_google_01',
      email: 'rajesh.murmu.edu@gmail.com',
      displayName: 'Shri Rajesh Murmu (Teacher)',
      schoolName: 'Govt. Primary Tribal Model School, Dumka',
      district: 'Dumka, Jharkhand',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTeacherLoggedIn, true);

    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (email.trim().isEmpty) {
      throw Exception('कृपया अपना पंजीकृत ईमेल दर्ज करें।');
    }
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTeacherLoggedIn, false);
    _controller.add(null);
  }
}
