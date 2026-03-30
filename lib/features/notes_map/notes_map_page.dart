import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/core/constants/app_constants.dart';
import 'package:notes_app/features/auth/auth_provider.dart';
import 'package:notes_app/features/notes_map/notes_map_provider.dart';

/// Notes map page
class NotesMapPage extends StatefulWidget {
  final Function(String noteId)? onMarkerTapped;

  const NotesMapPage({super.key, this.onMarkerTapped});

  @override
  State<NotesMapPage> createState() => _NotesMapPageState();
}

class _NotesMapPageState extends State<NotesMapPage> {
  late MapController _mapController;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthStateNotifier>();
      if (authState.currentUser != null) {
        context.read<NotesMapNotifier>().initializeNotes(
          authState.currentUser!.uid,
        );
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _updateMarkers(List<dynamic> notes) {
    _markers = [];

    for (var note in notes) {
      final marker = Marker(
        point: LatLng(note.latitude, note.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            widget.onMarkerTapped?.call(note.id);
            _showNotePopup(note);
          },
          child: Tooltip(
            message: note.title,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
      _markers.add(marker);
    }

    setState(() {});
  }

  void _showNotePopup(dynamic note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(note.title),
          content: Text(
            note.body.length > 100
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
      body: Consumer<NotesMapNotifier>(
        builder: (context, notesMapProvider, _) {
          // Update markers when notes change
          if (notesMapProvider.notes.isNotEmpty) {
            Future.microtask(() => _updateMarkers(notesMapProvider.notes));
          }

          // Loading state
          if (notesMapProvider.isLoading && notesMapProvider.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (notesMapProvider.errorMessage != null) {
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
                      notesMapProvider.errorMessage ?? 'Unknown error',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    ElevatedButton(
                      onPressed: () {
                        final authState = context.read<AuthStateNotifier>();
                        if (authState.currentUser != null) {
                          context.read<NotesMapNotifier>().initializeNotes(
                            authState.currentUser!.uid,
                          );
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
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
