import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/features/auth/auth_provider.dart';
import 'package:notes_app/features/note_editor/note_editor_provider.dart';
import 'package:notes_app/features/note_editor/editor_widgets.dart';
import 'package:notes_app/core/services/permission_service.dart';
import 'package:notes_app/core/services/image_compression_service.dart';

/// Note editor page for creating and editing notes
class NoteEditorPage extends StatefulWidget {
  final String? noteId;
  final VoidCallback? onSave;

  const NoteEditorPage({super.key, this.noteId, this.onSave});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedImageBase64;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editorProvider = context.read<NoteEditorNotifier>();

      editorProvider.reset();

      if (widget.noteId != null) {
        editorProvider.loadNote(widget.noteId!);
      } else {
        editorProvider.initializeForNewNote();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final editorProvider = context.watch<NoteEditorNotifier>();

    if (editorProvider.currentNote != null) {
      _titleController.text = editorProvider.currentNote!.title;
      _bodyController.text = editorProvider.currentNote!.body;
    }
  }

  Future<void> _pickImage() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to pick the image from:'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Camera'),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImageFromSource(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final permissionService = PermissionService();

    try {
      // Check permission status first
      late PermissionStatusResult permissionStatus;
      if (source == ImageSource.camera) {
        permissionStatus = await permissionService
            .checkCameraPermissionStatus();
      } else {
        permissionStatus = await permissionService
            .checkStoragePermissionStatus();
      }

      // Handle different permission statuses
      if (permissionStatus == PermissionStatusResult.granted) {
        await _performImagePick(source);
      } else if (permissionStatus == PermissionStatusResult.permanentlyDenied) {
        if (mounted) {
          _showPermissionPermanentlyDeniedDialog(
            context,
            source,
            permissionService,
          );
        }
      } else {
        // Permission not granted yet, request it
        late PermissionStatusResult requestResult;
        if (source == ImageSource.camera) {
          requestResult = await permissionService
              .requestCameraPermissionIfNeeded();
        } else {
          requestResult = await permissionService
              .requestStoragePermissionIfNeeded();
        }

        if (requestResult == PermissionStatusResult.granted) {
          if (mounted) {
            await _performImagePick(source);
          }
        } else if (requestResult == PermissionStatusResult.permanentlyDenied) {
          if (mounted) {
            _showPermissionPermanentlyDeniedDialog(
              context,
              source,
              permissionService,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  source == ImageSource.camera
                      ? 'Camera permission denied'
                      : 'Gallery permission denied',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  /// Perform the actual image picking and compress to Base64
  Future<void> _performImagePick(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null && mounted) {
        // Show loading indicator while compressing
        _showCompressionDialog();

        // Compress image and convert to Base64
        final imageCompressionService = ImageCompressionService();
        final base64String = await imageCompressionService
            .compressImageToBase64(imagePath: image.path, initialQuality: 90);

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          setState(() {
            _selectedImageBase64 = base64String;
          });

          final sizeKB = imageCompressionService.getBase64SizeInKB(
            base64String,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image compressed and ready (${sizeKB.toStringAsFixed(1)}KB)',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if still open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    }
  }

  /// Show compression progress dialog
  void _showCompressionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text('Compressing image...'),
            ],
          ),
        );
      },
    );
  }

  /// Show dialog when permission is permanently denied
  void _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
    ImageSource source,
    PermissionService permissionService,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final title = source == ImageSource.camera
            ? 'Camera Access Required'
            : 'Gallery Access Required';
        final message = source == ImageSource.camera
            ? 'Camera permission is permanently denied. '
                  'Please enable it in app settings to take photos for your notes.'
            : 'Gallery permission is permanently denied. '
                  'Please enable it in app settings to add images from your device.';

        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                permissionService.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Save note - userId is retrieved from Firebase Auth internally
      context.read<NoteEditorNotifier>().saveNote(
        title: _titleController.text,
        body: _bodyController.text,
        imageBase64: _selectedImageBase64,
      );

      widget.onSave?.call();
      Navigator.of(context).pop();
    }
  }

  void _handleDelete() {
    final editorProvider = context.read<NoteEditorNotifier>();

    if (editorProvider.currentNote == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete note - userId is retrieved from Firebase Auth internally
                editorProvider.deleteNote(editorProvider.currentNote!.id);
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Note' : 'New Note'),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.noteId != null)
            Selector<NoteEditorNotifier, bool>(
              selector: (context, provider) => provider.currentNote != null,
              builder: (context, hasNote, _) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: hasNote ? _handleDelete : null,
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message - uses Selector for granular update
                  Selector<NoteEditorNotifier, String?>(
                    selector: (context, provider) => provider.errorMessage,
                    builder: (context, errorMessage, _) {
                      if (errorMessage != null) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingMd,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingMd),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: const Border(
                                left: BorderSide(
                                  color: AppTheme.errorColor,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                Expanded(
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(
                                      color: AppTheme.errorColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Title field
                  EditorTextField(
                    label: 'Title',
                    hint: 'Enter note title',
                    controller: _titleController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Body field
                  EditorTextField(
                    label: 'Description',
                    hint: 'Enter note description',
                    controller: _bodyController,
                    maxLines: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Location info - uses Selector for granular update
                  Selector<NoteEditorNotifier, (double?, double?, bool)>(
                    selector: (context, provider) => (
                      provider.latitude,
                      provider.longitude,
                      provider.isLocationLoading,
                    ),
                    builder: (context, locationData, _) {
                      final (latitude, longitude, isLocationLoading) =
                          locationData;
                      return LocationInfoWidget(
                        latitude: latitude,
                        longitude: longitude,
                        isLoading: isLocationLoading,
                        onRefresh: () {
                          context.read<NoteEditorNotifier>().updateLocation();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Image section - uses Selector for image updates
                  Selector<NoteEditorNotifier, String?>(
                    selector: (context, provider) =>
                        provider.currentNote?.imageBase64,
                    builder: (context, noteImageBase64, _) {
                      if (_selectedImageBase64 != null ||
                          noteImageBase64 != null) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingMd,
                          ),
                          child: ImagePreviewWidget(
                            imageBase64:
                                _selectedImageBase64 ?? noteImageBase64,
                            onRemove: () {
                              setState(() {
                                _selectedImageBase64 = null;
                              });
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Buttons - uses Selector for loading state
                  Selector<NoteEditorNotifier, bool>(
                    selector: (context, provider) => provider.isLoading,
                    builder: (context, isLoading, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              label: 'Add Image',
                              icon: Icons.image_outlined,
                              onPressed: _pickImage,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: ActionButton(
                              label: 'Save',
                              icon: Icons.save_outlined,
                              onPressed: _handleSave,
                              isLoading: isLoading,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Loading overlay
          Selector<NoteEditorNotifier, bool>(
            selector: (context, provider) =>
                provider.isLoading && provider.currentNote == null,
            builder: (context, isLoadingNote, _) {
              if (isLoadingNote) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
