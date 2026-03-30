import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/note_editor/note_editor_repository.dart';

/// Implementation of NoteEditorRepository
class NoteEditorRepositoryImpl implements NoteEditorRepository {
  final FirestoreService _firestoreService;

  NoteEditorRepositoryImpl(this._firestoreService);

  @override
  Future<String> createNote(Note note) async {
    try {
      final noteId = await _firestoreService.addNote(note.userId, note.toMap());
      return noteId;
    } catch (e) {
      throw Exception('Failed to create note: ${e.toString()}');
    }
  }

  @override
  Future<void> updateNote(Note note) async {
    try {
      await _firestoreService.updateNote(note.userId, note.id, note.toMap());
    } catch (e) {
      throw Exception('Failed to update note: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestoreService.deleteNote(userId, noteId);
    } catch (e) {
      throw Exception('Failed to delete note: ${e.toString()}');
    }
  }

  @override
  Future<Note?> getNote(String userId, String noteId) async {
    try {
      final noteMap = await _firestoreService.getNote(userId, noteId);
      if (noteMap != null) {
        return Note.fromMap(noteMap, noteId);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch note: ${e.toString()}');
    }
  }
}
