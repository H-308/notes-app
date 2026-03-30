import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/core/constants/app_constants.dart';

/// Service for Firebase authentication operations
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  factory FirebaseAuthService() {
    return _instance;
  }

  FirebaseAuthService._internal();

  /// Get current user stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception(AppConstants.unknownError);
    }
  }

  /// Handle Firebase auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AppConstants.emailInUseError;
      case 'user-not-found':
        return AppConstants.userNotFoundError;
      case 'wrong-password':
        return AppConstants.wrongPasswordError;
      case 'invalid-email':
        return AppConstants.invalidEmailError;
      case 'weak-password':
        return AppConstants.weakPasswordError;
      case 'user-disabled':
        return AppConstants.userDisabledError;
      default:
        return AppConstants.unknownError;
    }
  }
}
