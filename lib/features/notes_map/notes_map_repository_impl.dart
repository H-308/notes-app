import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/notes_map/notes_map_repository.dart';

/// Implementation of NotesMapRepository
class NotesMapRepositoryImpl implements NotesMapRepository {
  final FirestoreService _firestoreService;

  NotesMapRepositoryImpl(this._firestoreService);

  @override
  Stream<List<Note>> getNotes(String userId) {
    try {
      return _firestoreService.getAllNotes(userId).map((snapshot) {
        return snapshot.docs
            .map((doc) => Note.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
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
