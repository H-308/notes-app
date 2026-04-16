import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/notes_list/notes_list_repository_impl.dart';
import 'package:notes_app/features/notes_list/notes_list_repository.dart';

/// Provider for NotesListRepository
final notesListRepositoryProvider = Provider<NotesListRepository>(
  create: (ref) {
    final firestoreService = FirestoreService();
    return NotesListRepositoryImpl(firestoreService);
  },
);

/// Notifier for managing notes list state
class NotesListNotifier extends ChangeNotifier {
  final NotesListRepository _repository;

  NotesListNotifier(this._repository) {
    _sessionStartedAt = DateTime.now();
    _initialAuthCheckTimer = Timer(const Duration(milliseconds: 1500), () {
      _isInitialAuthCheck = false;
      notifyListeners();
    });
  }

  List<Note> _notes = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitialAuthCheck = true;
  bool _shouldShowWelcomeDialog = false;
  bool _hasTriggeredWelcomeDialogThisSession = false;
  late DateTime _sessionStartedAt;
  StreamSubscription<List<Note>>? _notesSubscription;
  Timer? _initialAuthCheckTimer;

  List<Note> get notes => _notes;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isEmpty => _notes.isEmpty;
  bool get isInitialAuthCheck => _isInitialAuthCheck;
  bool get shouldShowWelcomeDialog => _shouldShowWelcomeDialog;

  bool get _isWithinStartupAuthErrorWindow =>
      DateTime.now().difference(_sessionStartedAt) < const Duration(seconds: 3);

  bool get _hasStartupUnauthenticatedError {
    final message = _errorMessage?.toLowerCase() ?? '';
    return message.contains('user not authenticated');
  }

  bool get shouldShowErrorUi {
    if (_errorMessage == null) return false;
    if (_isLoading || _isInitialAuthCheck) return false;
    if (_hasStartupUnauthenticatedError && _isWithinStartupAuthErrorWindow) {
      return false;
    }
    return true;
  }

  /// Reset all state when user logs out or auth changes
  void reset() {
    _notes = [];
    _errorMessage = null;
    _isLoading = false;
    _isInitialAuthCheck = true;
    _shouldShowWelcomeDialog = false;
    _hasTriggeredWelcomeDialogThisSession = false;
    _sessionStartedAt = DateTime.now();

    // Cancel any active subscriptions
    _notesSubscription?.cancel();
    _notesSubscription = null;

    // Reset auth check timer
    _initialAuthCheckTimer?.cancel();
    _initialAuthCheckTimer = Timer(const Duration(milliseconds: 1500), () {
      _isInitialAuthCheck = false;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Initialize notes
  Future<void> initializeNotes() async {
    _notes = [];
    _isLoading = true;
    _errorMessage = null;
    _shouldShowWelcomeDialog = false;
    _hasTriggeredWelcomeDialogThisSession = false;
    notifyListeners();

    try {
      await _notesSubscription?.cancel();
      _notesSubscription = null;

      _notesSubscription = _repository.getNotes().listen(
        (notes) {
          _notes = notes;
          _isLoading = false;
          _isInitialAuthCheck = false;

          if (!_hasTriggeredWelcomeDialogThisSession) {
            _shouldShowWelcomeDialog = true;
            _hasTriggeredWelcomeDialogThisSession = true;
          }
          notifyListeners();
        },
        onError: (error) {
          _isLoading = false;
          _isInitialAuthCheck = false;
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    } catch (e) {
      _isLoading = false;
      _isInitialAuthCheck = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete a note
  Future<void> deleteNote(String noteId) async {
    try {
      await _repository.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void consumeWelcomeDialogTrigger() {
    _shouldShowWelcomeDialog = false;
  }

  @override
  void dispose() {
    _initialAuthCheckTimer?.cancel();
    _notesSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for NotesListNotifier
final notesListProvider = ChangeNotifierProvider<NotesListNotifier>(
  create: (ref) {
    final repository = NotesListRepositoryImpl(FirestoreService());
    return NotesListNotifier(repository);
  },
);
