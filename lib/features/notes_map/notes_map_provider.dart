import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/notes_map/notes_map_repository_impl.dart';
import 'package:notes_app/features/notes_map/notes_map_repository.dart';

/// Provider for NotesMapRepository
final notesMapRepositoryProvider = Provider<NotesMapRepository>(
  create: (ref) {
    final firestoreService = FirestoreService();
    return NotesMapRepositoryImpl(firestoreService);
  },
);

/// Notifier for managing notes map state
class NotesMapNotifier extends ChangeNotifier {
  final NotesMapRepository _repository;

  NotesMapNotifier(this._repository);

  List<Note> _notes = [];
  String? _errorMessage;
  bool _isLoading = false;
  StreamSubscription<List<Note>>? _notesSubscription;

  List<Note> get notes => _notes;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isEmpty => _notes.isEmpty;

  /// Reset all state when user logs out or auth changes
  void reset() {
    _notes = [];
    _errorMessage = null;
    _isLoading = false;

    // Cancel any active subscriptions
    _notesSubscription?.cancel();
    _notesSubscription = null;

    notifyListeners();
  }

  /// Initialize notes stream listener
  /// No userId parameter - FirebaseAuth is used internally
  /// Waits for Firebase Auth to initialize before attempting to fetch notes
  Future<void> initializeNotes() async {
    // Clear notes immediately for the new user - ensures old notes vanish instantly
    _notes = [];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Give Firebase Auth time to initialize if needed
      await Future.delayed(const Duration(milliseconds: 300));

      // Cancel any active subscriptions to prevent multiple listeners
      await _notesSubscription?.cancel();
      _notesSubscription = null;

      _notesSubscription = _repository.getNotes().listen(
        (notes) {
          _notes = notes;
          _errorMessage = null;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for NotesMapNotifier
final notesMapProvider = ChangeNotifierProvider<NotesMapNotifier>(
  create: (ref) {
    final repository = NotesMapRepositoryImpl(FirestoreService());
    return NotesMapNotifier(repository);
  },
);
