import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  List<Note> get notes => _notes;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isEmpty => _notes.isEmpty;

  /// Initialize notes stream listener
  void initializeNotes(String userId) {
    _isLoading = true;
    notifyListeners();

    _repository
        .getNotes(userId)
        .listen(
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
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

/// Provider for NotesMapNotifier
final notesMapProvider = ChangeNotifierProvider<NotesMapNotifier>(
  create: (ref) {
    final repository = NotesMapRepositoryImpl(FirestoreService());
    return NotesMapNotifier(repository);
  },
);
