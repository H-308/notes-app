import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/note_editor/note_editor_repository.dart';

/// Implementation of NoteEditorRepository
/// Uses FirestoreService which retrieves UID from Firebase Auth internally
class NoteEditorRepositoryImpl implements NoteEditorRepository {
  final FirestoreService _firestoreService;

  NoteEditorRepositoryImpl(this._firestoreService);

  @override
  Future<String> createNote(Note note) async {
    try {
      await _firestoreService.addNote(note.toMap());
      return note.id;
    } catch (e) {
      throw Exception('Failed to create note: ${e.toString()}');
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    try {
      await _firestoreService.updateNote(note.id, note.toMap());
    } catch (e) {
      throw Exception('Failed to update note: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      await _firestoreService.deleteNote(noteId);
    } catch (e) {
      throw Exception('Failed to delete note: ${e.toString()}');
    }
  }

  @override
  Future<Note?> getNote(String noteId) async {
    try {
      final noteMap = await _firestoreService.getNote(noteId);
      if (noteMap != null) {
        return Note.fromMap(noteMap, noteId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch note: ${e.toString()}');
    }
  }
}
