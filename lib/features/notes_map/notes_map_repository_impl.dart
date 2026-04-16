import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/notes_map/notes_map_repository.dart';

/// Implementation of NotesMapRepository
/// Uses FirestoreService which retrieves UID from Firebase Auth internally
class NotesMapRepositoryImpl implements NotesMapRepository {
  final FirestoreService _firestoreService;

  NotesMapRepositoryImpl(this._firestoreService);

  @override
  Stream<List<Note>> getNotes() {
    try {
      return _firestoreService.getAllNotes().map((snapshot) {
        return snapshot.docs
            .map((doc) => Note.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
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
