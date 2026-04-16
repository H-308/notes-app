import 'package:notes_app/models/note.dart';

/// Abstract repository for note editor operations
/// All methods use the currently authenticated user from Firebase Auth
abstract class NoteEditorRepository {
  /// Create a new note
  Future<String> createNote(Note note);

  /// Update an existing note
  Future<void> updateNote(Note note);

  /// Delete a note by ID
  Future<void> deleteNote(String noteId);

  /// Get a note by ID
  Future<Note?> getNote(String noteId);
}
