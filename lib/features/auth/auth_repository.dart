import 'package:firebase_auth/firebase_auth.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
  });

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  });

  /// Sign out
  Future<void> signOut();

  /// Get auth state changes stream
  Stream<User?> get authStateChanges;

  /// Get current user
  User? getCurrentUser();
}
