import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/core/constants/app_constants.dart';
import 'package:notes_app/features/auth/auth_provider.dart';
import 'package:notes_app/features/notes_map/notes_map_provider.dart';
import 'package:notes_app/features/notes_map/note_location_cluster.dart';
import 'package:notes_app/features/notes_map/notes_at_location_bottom_sheet.dart';
import 'package:notes_app/models/note.dart';

/// Notes map page
class NotesMapPage extends StatefulWidget {
  final Function(String noteId)? onMarkerTapped;

  const NotesMapPage({super.key, this.onMarkerTapped});

  @override
  State<NotesMapPage> createState() => _NotesMapPageState();
}

class _NotesMapPageState extends State<NotesMapPage> {
  late final MapController _mapController;
  late NotesMapNotifier _notesMapNotifier;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize map notes - no userId needed, FirebaseAuth is used internally
      _notesMapNotifier = context.read<NotesMapNotifier>();
      _notesMapNotifier.initializeNotes();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Build markers from clusters - efficient list generation
  List<Marker> _buildMarkers(List<NoteLocationCluster> clusters) {
    return clusters.map((cluster) {
      return Marker(
        point: cluster.point,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            if (cluster.isSingleNote) {
              // Single note: show popup dialog
              widget.onMarkerTapped?.call(cluster.notes[0].id);
              _showNotePopup(cluster.notes[0]);
            } else {
              // Multiple notes: show bottom sheet
              NotesAtLocationBottomSheet.show(
                context,
                notes: cluster.notes,
                onNoteTapped: widget.onMarkerTapped,
              );
            }
          },
          child: _NoteMarkerWidget(cluster: cluster),
        ),
      );
    }).toList();
  }

  void _showNotePopup(Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(note.title.isEmpty ? 'Untitled Note' : note.title),
          content: Text(
            note.body.isEmpty
                ? 'No description'
                : note.body.length > 100
                ? '${note.body.substring(0, 100)}...'
                : note.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onMarkerTapped?.call(note.id);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes Map'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Selector<NotesMapNotifier, (List<Note>, bool, String?)>(
        selector: (context, provider) => (
          provider.notes,
          provider.isLoading && provider.isEmpty,
          provider.errorMessage,
        ),
        builder: (context, state, _) {
          final (notes, isLoading, errorMessage) = state;

          // Cluster and build markers only when notes change
          final clusters = notes.isNotEmpty
              ? LocationClusteringService.clusterNotesByLocation(notes)
              : <NoteLocationCluster>[];
          final markers = clusters.isNotEmpty
              ? _buildMarkers(clusters)
              : <Marker>[];

          // Loading state
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'Oops! Something went wrong',
                      style: AppTheme.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      errorMessage,
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    ElevatedButton(
                      onPressed: () {
                        final authState = context.read<AuthStateNotifier>();
                        if (authState.currentUser != null) {
                          context.read<NotesMapNotifier>().initializeNotes();
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Map with markers
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                AppConstants.defaultLatitude,
                AppConstants.defaultLongitude,
              ),
              initialZoom: AppConstants.defaultZoom,
              minZoom: 2.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.notes_app',
              ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
            child: const Icon(Icons.add),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
            child: const Icon(Icons.remove),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'center_map',
            mini: true,
            onPressed: () {
              _mapController.move(
                LatLng(
                  AppConstants.defaultLatitude,
                  AppConstants.defaultLongitude,
                ),
                AppConstants.defaultZoom,
              );
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

/// Const widget for marker UI to prevent unnecessary rebuilds
class _NoteMarkerWidget extends StatelessWidget {
  final NoteLocationCluster cluster;

  const _NoteMarkerWidget({required this.cluster});

  @override
  Widget build(BuildContext context) {
    if (cluster.isSingleNote) {
      return Tooltip(
        message: cluster.notes[0].title.isEmpty
            ? 'Untitled Note'
            : cluster.notes[0].title,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
        ),
      );
    } else {
      // Cluster marker with note count
      final color = LocationClusteringService.getClusterColor(
        cluster.notes.length,
      );
      return Container(
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Color(color).withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            cluster.notes.length.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }
  }
}
