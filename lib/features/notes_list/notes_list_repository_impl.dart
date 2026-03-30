import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/models/note.dart';
import 'package:notes_app/features/notes_list/notes_list_repository.dart';

/// Implementation of NotesListRepository
class NotesListRepositoryImpl implements NotesListRepository {
  final FirestoreService _firestoreService;

  NotesListRepositoryImpl(this._firestoreService);

  @override
  Stream<List<Note>> getNotes(String userId) {
    try {
      return _firestoreService.getNotesSortedByDate(userId).map((snapshot) {
        return snapshot.docs
            .map((doc) => Note.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
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
}
