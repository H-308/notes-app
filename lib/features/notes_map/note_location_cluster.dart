import 'package:latlong2/latlong.dart';
import 'package:notes_app/models/note.dart';

/// Represents a cluster of notes at a specific location
class NoteLocationCluster {
  final double latitude;
  final double longitude;
  final List<Note> notes;

  NoteLocationCluster({
    required this.latitude,
    required this.longitude,
    required this.notes,
  });

  /// Check if this cluster contains only one note
  bool get isSingleNote => notes.length == 1;

  /// Get the LatLng point for this cluster
  LatLng get point => LatLng(latitude, longitude);
}

/// Utility class for grouping notes by location
class LocationClusteringService {
  /// Tolerance in decimal degrees (approximately 1 meter at equator)
  static const double _defaultTolerance = 0.00001;

  /// Group notes by their coordinates with tolerance
  static List<NoteLocationCluster> clusterNotesByLocation(
    List<Note> notes, {
    double tolerance = _defaultTolerance,
  }) {
    final clusters = <NoteLocationCluster>[];
    final processedIndices = <int>{};

    for (int i = 0; i < notes.length; i++) {
      if (processedIndices.contains(i)) continue;

      final currentNote = notes[i];
      final notesAtLocation = <Note>[currentNote];
      processedIndices.add(i);

      // Find all notes within tolerance of current note
      for (int j = i + 1; j < notes.length; j++) {
        if (processedIndices.contains(j)) continue;

        final otherNote = notes[j];
        if (_isWithinTolerance(
          currentNote.latitude,
          currentNote.longitude,
          otherNote.latitude,
          otherNote.longitude,
          tolerance,
        )) {
          notesAtLocation.add(otherNote);
          processedIndices.add(j);
        }
      }

      clusters.add(
        NoteLocationCluster(
          latitude: currentNote.latitude,
          longitude: currentNote.longitude,
          notes: notesAtLocation,
        ),
      );
    }

    return clusters;
  }

  /// Check if two coordinates are within tolerance
  static bool _isWithinTolerance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
    double tolerance,
  ) {
    return (lat1 - lat2).abs() < tolerance &&
        (lon1 - lon2).abs() < tolerance;
  }

  /// Get a cluster color based on the number of notes
  static int getClusterColor(int noteCount) {
    if (noteCount == 1) return 0xFF4CAF50; // Green
    if (noteCount <= 3) return 0xFFFFA726; // Orange
    if (noteCount <= 5) return 0xFFEF5350; // Red
    return 0xFF8E24AA; // Purple for many
  }

  /// Get a cluster label
  static String getClusterLabel(int noteCount) {
    return noteCount > 1 ? '$noteCount' : '';
  }
}
