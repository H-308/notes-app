import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/core/services/location_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/note_editor/note_editor_repository_impl.dart';
import 'package:notes_app/features/note_editor/note_editor_repository.dart';

/// Provider for NoteEditorRepository
final noteEditorRepositoryProvider = Provider<NoteEditorRepository>(
  create: (ref) {
    final firestoreService = FirestoreService();
    return NoteEditorRepositoryImpl(firestoreService);
  },
);

/// Notifier for managing note editor state
/// Uses Firebase Auth as the authoritative source for userId
class NoteEditorNotifier extends ChangeNotifier {
  final NoteEditorRepository _repository;
  final LocationService _locationService;

  NoteEditorNotifier(this._repository, this._locationService);

  Note? _currentNote;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  double? _latitude;
  double? _longitude;

  Note? get currentNote => _currentNote;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLocationLoading => _isLocationLoading;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  /// Load existing note
  /// No userId parameter - FirebaseAuth is used internally
  Future<void> loadNote(String noteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentNote = await _repository.getNote(noteId);
      if (_currentNote != null) {
        _latitude = _currentNote!.latitude;
        _longitude = _currentNote!.longitude;
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialize for new note with current location
  Future<void> initializeForNewNote() async {
    _isLocationLoading = true;
    _errorMessage = null;
    _currentNote = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      _latitude = location.$1;
      _longitude = location.$2;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      // Set default location on error
      _latitude = 37.7749;
      _longitude = -122.4194;
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  /// Save note (create or update)
  Future<void> saveNote({
    required String title,
    required String body,
    String? imageBase64,
  }) async {
    if (title.isEmpty || body.isEmpty) {
      _errorMessage = 'Title and body are required';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated via Firebase');
      }

      final note = Note(
        id: _currentNote?.id ?? const Uuid().v4(),
        title: title,
        body: body,
        latitude: _latitude ?? 0,
        longitude: _longitude ?? 0,
        createdAt: _currentNote?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        imageBase64: imageBase64 ?? _currentNote?.imageBase64,
        userId: userId,
      );

      if (_currentNote == null) {
        // Create new note
        await _repository.createNote(note);
      } else {
        // Update existing note
        await _repository.updateNote(note);
      }

      _currentNote = note;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete note
  /// No userId parameter - FirebaseAuth is used internally
  Future<void> deleteNote(String noteId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteNote(noteId);
      _currentNote = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update location
  Future<void> updateLocation() async {
    _isLocationLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final location = await _locationService.getCurrentLocation();
      _latitude = location.$1;
      _longitude = location.$2;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset editor
  void reset() {
    _currentNote = null;
    _latitude = null;
    _longitude = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

/// Provider for NoteEditorNotifier
final noteEditorProvider = ChangeNotifierProvider<NoteEditorNotifier>(
  create: (ref) {
    final repository = NoteEditorRepositoryImpl(FirestoreService());
    final locationService = LocationService();
    return NoteEditorNotifier(repository, locationService);
  },
);
