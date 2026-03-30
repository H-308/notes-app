import 'package:notes_app/models/note.dart';

/// Abstract repository for notes map operations
abstract class NotesMapRepository {
  /// Get all notes for the current user
  Stream<List<Note>> getNotes(String userId);

  /// Get a single note by ID
  Future<Note?> getNote(String userId, String noteId);
}
