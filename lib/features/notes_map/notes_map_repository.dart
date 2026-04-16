import 'package:notes_app/models/note.dart';

/// Abstract repository for notes map operations
/// All methods use the currently authenticated user from Firebase Auth
abstract class NotesMapRepository {
  /// Get all notes for the current user
  Stream<List<Note>> getNotes();

  /// Get a single note by ID
  Future<Note?> getNote(String noteId);
}
