import 'package:flutter/material.dart';
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

  NotesListNotifier(this._repository);

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

  /// Delete a note
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _repository.deleteNote(userId, noteId);
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
}

/// Provider for NotesListNotifier
final notesListProvider = ChangeNotifierProvider<NotesListNotifier>(
  create: (ref) {
    final repository = NotesListRepositoryImpl(FirestoreService());
    return NotesListNotifier(repository);
  },
);
