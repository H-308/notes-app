/// Represents the auth state of the application
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

/// Auth user entity
class AuthUser {
  final String uid;
  final String email;
  final String? displayName;

  AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  factory AuthUser.fromFirebaseUser(dynamic firebaseUser) {
    return AuthUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
    );
  }
}
