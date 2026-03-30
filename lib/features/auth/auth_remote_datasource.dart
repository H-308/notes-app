import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/core/services/firebase_auth_service.dart';

/// Remote data source for authentication
class AuthRemoteDataSource {
  final FirebaseAuthService _firebaseAuthService;

  AuthRemoteDataSource(this._firebaseAuthService);

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuthService.signUp(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuthService.signIn(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    return await _firebaseAuthService.signOut();
  }

  /// Get auth state changes stream
  Stream<User?> getAuthStateChanges() {
    return _firebaseAuthService.authStateChanges;
  }

  /// Get current user
  User? getCurrentUser() {
    return _firebaseAuthService.currentUser;
  }
}
