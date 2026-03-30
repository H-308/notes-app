import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/features/auth/auth_remote_datasource.dart';
import 'package:notes_app/features/auth/auth_repository.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _remoteDataSource.signUp(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _remoteDataSource.signIn(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.getAuthStateChanges();

  @override
  User? getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }
}
