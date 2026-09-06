import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_model.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  // GoogleSignIn is initialized only once.
  static bool _googleInitialized = false;

  final StreamController<TeacherUser?> _controller =
      StreamController<TeacherUser?>.broadcast();

  TeacherUser? _currentUser;

  FirebaseAuthService() {
    // Listen for Firebase authentication state changes.
    fb.FirebaseAuth.instance.authStateChanges().listen(
      _handleFirebaseUser,
    );
  }

  // -------------------------------------------------------------------------
  // FIREBASE AUTH STATE
  // -------------------------------------------------------------------------

  Future<void> _handleFirebaseUser(fb.User? fbUser) async {
    if (fbUser == null) {
      _currentUser = null;

      if (!_controller.isClosed) {
        _controller.add(null);
      }

      return;
    }

    try {
      final teacher = await _mapFirebaseUserToTeacher(fbUser);

      _currentUser = teacher;

      if (!_controller.isClosed) {
        _controller.add(teacher);
      }
    } catch (e) {
      // User is authenticated in Firebase but is not an authorized teacher.
      await _signOutInternal();
    }
  }

  // -------------------------------------------------------------------------
  // FIRESTORE TEACHER PROFILE
  // -------------------------------------------------------------------------

  Future<TeacherUser> _mapFirebaseUserToTeacher(
    fb.User fbUser,
  ) async {
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(fbUser.uid)
        .get();

    if (!doc.exists) {
      throw Exception(
        'अधिकृत शिक्षक प्रोफ़ाइल नहीं मिली '
        '(Teacher profile not found).',
      );
    }

    final data = doc.data();

    if (data == null) {
      throw Exception(
        'शिक्षक प्रोफ़ाइल डेटा नहीं मिला '
        '(Teacher profile data not found).',
      );
    }

    // Only users with role = teacher are allowed.
    if (data['role'] != 'teacher') {
      throw Exception(
        'इस उपयोगकर्ता को शिक्षक के रूप में अधिकृत नहीं किया गया है '
        '(User not authorized as teacher).',
      );
    }

    return TeacherUser(
      uid: fbUser.uid,
      email: data['email'] as String? ?? fbUser.email ?? '',
      displayName:
          data['name'] as String? ?? fbUser.displayName ?? '',
      schoolName: data['school'] as String? ?? '',
      district: data['district'] as String? ?? '',
      photoUrl: fbUser.photoURL ?? '',
      isEmailVerified: fbUser.emailVerified,
    );
  }

  // -------------------------------------------------------------------------
  // AUTH STATE STREAM
  // -------------------------------------------------------------------------

  @override
  Stream<TeacherUser?> get authStateChanges => _controller.stream;

  @override
  TeacherUser? get currentUser => _currentUser;

  // -------------------------------------------------------------------------
  // EMAIL + PASSWORD LOGIN
  // -------------------------------------------------------------------------

  @override
  Future<TeacherUser> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user;

      if (fbUser == null) {
        throw Exception(
          'प्रमाणीकरण विफल (Authentication failed).',
        );
      }

      final teacher = await _mapFirebaseUserToTeacher(fbUser);

      _currentUser = teacher;

      if (!_controller.isClosed) {
        _controller.add(teacher);
      }

      return teacher;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // CREATE TEACHER ACCOUNT (SIGN UP)
  // -------------------------------------------------------------------------

  @override
  Future<TeacherUser> createTeacherAccount({
    required String name,
    required String email,
    required String school,
    required String district,
    required String password,
  }) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = credential.user;

      if (fbUser == null) {
        throw Exception(
          'खाता निर्माण विफल (Account creation failed).',
        );
      }

      // Update user display name in Firebase Auth
      try {
        await fbUser.updateDisplayName(name.trim());
      } catch (_) {
        // Display name update failure is non-fatal
      }

      // Create Teacher profile in Firestore at teachers/{uid}
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(fbUser.uid)
          .set({
        'name': name.trim(),
        'email': email.trim(),
        'school': school.trim(),
        'district': district.trim(),
        'role': 'teacher',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final teacher = TeacherUser(
        uid: fbUser.uid,
        email: email.trim(),
        displayName: name.trim(),
        schoolName: school.trim(),
        district: district.trim(),
        photoUrl: fbUser.photoURL ?? '',
        isEmailVerified: fbUser.emailVerified,
      );

      _currentUser = teacher;

      if (!_controller.isClosed) {
        _controller.add(teacher);
      }

      return teacher;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // GOOGLE LOGIN
  // -------------------------------------------------------------------------

  @override
  Future<TeacherUser> signInWithGoogle() async {
    try {
      // Initialize GoogleSignIn singleton if not already done
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final authResult = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = authResult.user;

      if (fbUser == null) {
        throw Exception('प्रमाणीकरण विफल (Authentication failed).');
      }

      // Ensure teacher profile exists. Create minimal profile if missing.
      final teacherDocRef = FirebaseFirestore.instance.collection('teachers').doc(fbUser.uid);
      final teacherDoc = await teacherDocRef.get();
    debugPrint('FirebaseAuthService: teacherDoc exists=${teacherDoc.exists} for uid=${fbUser.uid}');

      if (!teacherDoc.exists) {
        await teacherDocRef.set({
          'name': fbUser.displayName?.trim() ?? '',
          'email': fbUser.email?.trim() ?? '',
          'role': 'teacher',
          'createdAt': FieldValue.serverTimestamp(),
        });
        // After ensuring existence, read role for logging
        final teacherDocAfter = await teacherDocRef.get();
        debugPrint('FirebaseAuthService: after ensure, role=${teacherDocAfter.data()?['role']}');
      }

      // Retrieve teacher profile and validate role.
      final teacher = await _mapFirebaseUserToTeacher(fbUser);

      _currentUser = teacher;

      if (!_controller.isClosed) {
        _controller.add(teacher);
      }

      return teacher;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e));
    } on GoogleSignInException catch (e) {
      throw Exception(_googleSignInErrorMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  // -------------------------------------------------------------------------
  // PASSWORD RESET
  // -------------------------------------------------------------------------

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e),
      );
    }
  }

  // -------------------------------------------------------------------------
  // SIGN OUT
  // -------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    try {
      await fb.FirebaseAuth.instance.signOut();

      await GoogleSignIn.instance.signOut();

      _currentUser = null;

      if (!_controller.isClosed) {
        _controller.add(null);
      }
    } catch (e) {
      // Even if Google sign-out has an issue, make sure local state is cleared.
      _currentUser = null;

      if (!_controller.isClosed) {
        _controller.add(null);
      }

      rethrow;
    }
  }

  // Internal sign-out used when the Firebase account is not an authorized
  // teacher. Avoids unnecessary recursive auth-state handling.
  Future<void> _signOutInternal() async {
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    _currentUser = null;

    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  // -------------------------------------------------------------------------
  // FIREBASE ERROR MESSAGES
  // -------------------------------------------------------------------------

  String _firebaseErrorMessage(
    fb.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'अमान्य ईमेल पता (Invalid email address).';

      case 'user-disabled':
        return 'उपयोगकर्ता निष्क्रिय है (User disabled).';

      case 'user-not-found':
        return 'उपयोगकर्ता मौजूद नहीं है (User not found).';

      case 'wrong-password':
        return 'गलत पासवर्ड (Wrong password).';

      case 'invalid-credential':
        return 'अमान्य क्रेडेंशियल (Invalid credential).';

      case 'email-already-in-use':
        return 'यह ईमेल पहले से उपयोग में है '
            '(Email is already in use).';

      case 'weak-password':
        return 'पासवर्ड बहुत कमजोर है '
            '(Password is too weak).';

      case 'operation-not-allowed':
        return 'यह साइन-इन विधि Firebase में सक्षम नहीं है '
            '(This sign-in method is not enabled).';

      case 'too-many-requests':
        return 'बहुत अधिक अनुरोध, कृपया बाद में प्रयास करें '
            '(Too many requests, please try again later).';

      case 'network-request-failed':
        return 'नेटवर्क त्रुटि '
            '(Network request failed).';

      case 'requires-recent-login':
        return 'कृपया दोबारा लॉगिन करें '
            '(Please sign in again).';

      case 'account-exists-with-different-credential':
        return 'इस ईमेल के लिए अलग साइन-इन विधि पहले से मौजूद है '
            '(An account already exists with a different sign-in method).';

      default:
        return e.message ??
            'अप्रत्याशित Firebase त्रुटि '
            '(Unexpected Firebase error).';
    }
  }

  // -------------------------------------------------------------------------
  // GOOGLE SIGN-IN ERROR MESSAGES
  // -------------------------------------------------------------------------

  String _googleSignInErrorMessage(
    GoogleSignInException e,
  ) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Google साइन-इन रद्द किया गया '
            '(Google sign-in cancelled).';

      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In configuration में समस्या है '
            '(Google Sign-In configuration error).';

      case GoogleSignInExceptionCode.interrupted:
        return 'Google साइन-इन बाधित हुआ '
            '(Google sign-in was interrupted).';

      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In UI उपलब्ध नहीं है '
            '(Google Sign-In UI unavailable).';

      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google provider configuration में समस्या है '
            '(Google provider configuration error).';

      default:
        return 'Google साइन-इन में समस्या हुई '
            '(Google sign-in failed): ${e.code}';
    }
  }

  // -------------------------------------------------------------------------
  // CLEANUP
  // -------------------------------------------------------------------------

  void dispose() {
    _controller.close();
  }
}