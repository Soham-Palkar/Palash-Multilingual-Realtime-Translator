import '../models/auth_model.dart';

/// Abstract Authentication Service interface.
/// Allows swapping between MockAuthService (now) and FirebaseAuthService (later)
/// without modifying any UI or business logic.
abstract class AuthService {
  Stream<TeacherUser?> get authStateChanges;
  TeacherUser? get currentUser;
  Future<TeacherUser> signInWithEmailPassword(String email, String password);
  Future<TeacherUser> signInWithGoogle();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
