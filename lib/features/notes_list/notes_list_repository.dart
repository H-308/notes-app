import 'package:notes_app/models/note.dart';

/// Abstract repository for notes list operations
/// All methods use the currently authenticated user from Firebase Auth
abstract class NotesListRepository {
  /// Get all notes for the current user
  Stream<List<Note>> getNotes();

  /// Delete a note by ID
  Future<void> deleteNote(String noteId);
}
