import 'package:cloud_firestore/cloud_firestore.dart';

/// Note entity representing a location-based note
class Note {
  final String id;
  final String title;
  final String body;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final String userId;

  const Note({
    required this.id,
    required this.title,
    required this.body,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
    required this.userId,
  });

  /// Convert Note to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'imageUrl': imageUrl,
      'userId': userId,
    };
  }

  /// Create Note from Firestore document
  factory Note.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    return Note(
      id: docId,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      imageUrl: map['imageUrl'] as String?,
      userId: map['userId'] as String? ?? '',
    );
  }

  /// Create a copy with modified fields
  Note copyWith({
    String? id,
    String? title,
    String? body,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? userId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() =>
      'Note(id: $id, title: $title, latitude: $latitude, longitude: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          body == other.body &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          userId == other.userId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      userId.hashCode;
}
