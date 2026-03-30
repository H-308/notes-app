import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/features/auth/auth_remote_datasource.dart';
import 'package:notes_app/features/auth/auth_repository_impl.dart';
import 'package:notes_app/features/auth/auth_repository.dart';
import 'package:notes_app/core/services/firebase_auth_service.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>(
  create: (ref) {
    final authService = FirebaseAuthService();
    final remoteDataSource = AuthRemoteDataSource(authService);
    return AuthRepositoryImpl(remoteDataSource);
  },
);

/// Auth state notifier using Provider
class AuthStateNotifier extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) {
    _initializeUser();
  }

  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void _initializeUser() {
    _currentUser = _authRepository.getCurrentUser();
  }

  /// Sign up with email and password
  Future<void> signUp({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signUp(email: email, password: password);
      _currentUser = _authRepository.getCurrentUser();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signIn(email: email, password: password);
      _currentUser = _authRepository.getCurrentUser();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Listen to auth state changes
  Stream<User?> get authStateStream => _authRepository.authStateChanges;
}

/// Provider for AuthStateNotifier
final authStateProvider = ChangeNotifierProvider<AuthStateNotifier>(
  create: (ref) {
    final authService = FirebaseAuthService();
    final remoteDataSource = AuthRemoteDataSource(authService);
    final authRepository = AuthRepositoryImpl(remoteDataSource);
    return AuthStateNotifier(authRepository);
  },
);

/// Stream provider for auth state changes
final authStreamProvider = StreamProvider<User?>(
  initialData: null,
  create: (ref) {
    final authService = FirebaseAuthService();
    return authService.authStateChanges;
  },
);
