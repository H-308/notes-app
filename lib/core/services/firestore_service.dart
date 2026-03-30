import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notes_app/core/constants/app_constants.dart';

/// Service for Firestore database operations
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  /// Get notes collection reference for a user
  CollectionReference<Map<String, dynamic>> getUserNotesCollection(
    String userId,
  ) {
    return _firebaseFirestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.notesCollection);
  }

  /// Add a new note
  Future<String> addNote(
    String userId,
    Map<String, dynamic> noteData,
  ) async {
    try {
      final docRef = await getUserNotesCollection(userId).add(noteData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add note: ${e.toString()}');
    }
  }

  /// Update an existing note
  Future<void> updateNote(
    String userId,
    String noteId,
    Map<String, dynamic> noteData,
  ) async {
    try {
      await getUserNotesCollection(userId).doc(noteId).update(noteData);
    } catch (e) {
      throw Exception('Failed to update note: ${e.toString()}');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await getUserNotesCollection(userId).doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: ${e.toString()}');
    }
  }

  /// Get a single note by ID
  Future<Map<String, dynamic>?> getNote(
    String userId,
    String noteId,
  ) async {
    try {
      final doc = await getUserNotesCollection(userId).doc(noteId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch note: ${e.toString()}');
    }
  }

  /// Get all notes for a user
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllNotes(String userId) {
    try {
      return getUserNotesCollection(userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
    }
  }

  /// Get notes sorted by date (latest first)
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotesSortedByDate(
    String userId,
  ) {
    try {
      return getUserNotesCollection(userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
    }
  }
}
