import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notes_app/core/constants/app_constants.dart';

/// Service for Firestore database operations
/// CRITICAL: All methods retrieve the UID directly from Firebase Auth
/// This ensures we always use the currently authenticated user, never stale values
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  /// Get the current authenticated user's UID
  /// Throws if user is not authenticated
  String _getCurrentUID() {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated via Firebase');
    }
    return uid;
  }

  /// Get notes collection reference for the currently authenticated user
  /// Uses internal UID retrieval - never relies on passed parameters
  CollectionReference<Map<String, dynamic>> _getUserNotesCollection() {
    final String uid = _getCurrentUID();
    return _firebaseFirestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notesCollection);
  }

  /// Add a new note
  /// Uses currently authenticated user from Firebase Auth
  Future<void> addNote(Map<String, dynamic> noteData) async {
    try {
      final String noteId = noteData['id'];
      await _getUserNotesCollection().doc(noteId).set(noteData);
    } catch (e) {
      throw Exception('Failed to add note: ${e.toString()}');
    }
  }

  /// Update an existing note
  /// Uses currently authenticated user from Firebase Auth
  Future<void> updateNote(String noteId, Map<String, dynamic> noteData) async {
    try {
      await _getUserNotesCollection().doc(noteId).update(noteData);
    } catch (e) {
      throw Exception('Failed to update note: ${e.toString()}');
    }
  }

  /// Delete a note
  /// Uses currently authenticated user from Firebase Auth
  Future<void> deleteNote(String noteId) async {
    try {
      await _getUserNotesCollection().doc(noteId).delete();
    } catch (e) {
      throw Exception('Failed to delete note: ${e.toString()}');
    }
  }

  /// Get a single note by ID
  /// Uses currently authenticated user from Firebase Auth
  Future<Map<String, dynamic>?> getNote(String noteId) async {
    try {
      final doc = await _getUserNotesCollection().doc(noteId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch note: ${e.toString()}');
    }
  }

  /// Get all notes for the currently authenticated user
  /// Uses currently authenticated user from Firebase Auth
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllNotes() {
    try {
      return _getUserNotesCollection()
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
    }
  }

  /// Get notes sorted by date (latest first) for the currently authenticated user
  /// Uses currently authenticated user from Firebase Auth
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotesSortedByDate() {
    try {
      return _getUserNotesCollection()
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      throw Exception('Failed to fetch notes: ${e.toString()}');
    }
  }
}
