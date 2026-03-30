import 'package:notes_app/models/note.dart';

/// Abstract repository for note editor operations
abstract class NoteEditorRepository {
  /// Create a new note
  Future<String> createNote(Note note);

  /// Update an existing note
  Future<void> updateNote(Note note);

  /// Delete a note
  Future<void> deleteNote(String userId, String noteId);

  /// Get a note by ID
  Future<Note?> getNote(String userId, String noteId);
}
