import 'package:notes_app/models/note.dart';

/// Abstract repository for notes list operations
abstract class NotesListRepository {
  /// Get all notes for the current user
  Stream<List<Note>> getNotes(String userId);

  /// Delete a note
  Future<void> deleteNote(String userId, String noteId);
}
