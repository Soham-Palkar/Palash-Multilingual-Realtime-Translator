import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_model.dart';
import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  // ---- Configuration -----------------------------------------------------
  // Replace the placeholder with the actual Web OAuth client ID from Firebase console.
  // This value is public (not a secret) and is required for Android.
  static const String _webClientId = '<YOUR_WEB_CLIENT_ID>'; // TODO: set this value
  static bool _googleInitialized = false;

  final StreamController<TeacherUser?> _controller =
      StreamController<TeacherUser?>.broadcast();
  TeacherUser? _currentUser;

  FirebaseAuthService() {
    // Listen to Firebase auth state changes.
    fb.FirebaseAuth.instance.authStateChanges().listen(_handleFirebaseUser);
  }

  // Private helper to process Firebase User
  Future<void> _handleFirebaseUser(fb.User? fbUser) async {
    if (fbUser == null) {
      _currentUser = null;
      _controller.add(null);
      return;
    }
    try {
      final teacher = await _mapFirebaseUserToTeacher(fbUser);
      _currentUser = teacher;
      _controller.add(teacher);
    } catch (e) {
      // If mapping fails (e.g., missing profile or wrong role), sign out.
      await signOut();
      rethrow;
    }
  }

  // Fetch Firestore teacher document and map to TeacherUser
  Future<TeacherUser> _mapFirebaseUserToTeacher(fb.User fbUser) async {
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(fbUser.uid)
        .get();
    if (!doc.exists) {
      throw Exception('अधिकृत शिक्षक प्रोफ़ाइल नहीं मिली (Teacher profile not found).');
    }
    final data = doc.data()!;
    if (data['role'] != 'teacher') {
      throw Exception('इस उपयोगकर्ता को शिक्षक के रूप में अधिकृत नहीं किया गया है (User not authorized as teacher).');
    }
    return TeacherUser(
      uid: fbUser.uid,
      email: data['email'] as String? ?? fbUser.email ?? '',
      displayName: data['name'] as String? ?? fbUser.displayName ?? '',
      schoolName: data['school'] as String? ?? '',
      district: data['district'] as String? ?? '',
      photoUrl: fbUser.photoURL ?? '',
      isEmailVerified: fbUser.emailVerified,
    );
  }

  @override
  Stream<TeacherUser?> get authStateChanges => _controller.stream;

  @override
  TeacherUser? get currentUser => _currentUser;

  @override
  Future<TeacherUser> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await fb.FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('प्रमाणीकरण विफल (Authentication failed).');
      }
      final teacher = await _mapFirebaseUserToTeacher(fbUser);
      _currentUser = teacher;
      _controller.add(teacher);
      return teacher;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e));
    }
  }

  @override
  Future<TeacherUser> signInWithGoogle() async {
    try {
      // Initialise GoogleSignIn once with the required server client ID.
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
        _googleInitialized = true;
      }

      // ignore: unnecessary_nullable_for_final_variable_declarations
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        throw Exception('Google साइन‑इन रद्द किया गया (Google sign‑in cancelled).');
      }
      // In google_sign_in 7.x, authentication is a synchronous getter.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Google प्रमाणीकरण विफल (Google authentication failed).');
      }
      final teacher = await _mapFirebaseUserToTeacher(fbUser);
      _currentUser = teacher;
      _controller.add(teacher);
      return teacher;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    await fb.FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
    _controller.add(null);
  }

  // Helper to translate FirebaseAuthException codes to Hindi/English messages
  String _firebaseErrorMessage(fb.FirebaseAuthException e) {
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
      case 'too-many-requests':
        return 'बहुत अधिक अनुरोध, कृपया बाद में प्रयास करें (Too many requests).';
      case 'network-request-failed':
        return 'नेटवर्क त्रुटि (Network request failed).';
      default:
        return e.message ?? 'अप्रत्याशित त्रुटि (Unexpected error).';
    }
  }
}
