import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/features/auth/auth_provider.dart';
import 'package:notes_app/features/note_editor/note_editor_provider.dart';
import 'package:notes_app/features/note_editor/editor_widgets.dart';

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
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final editorProvider = context.read<NoteEditorNotifier>();
      editorProvider.reset();

      final authState = context.read<AuthStateNotifier>();

      if (widget.noteId != null && authState.currentUser != null) {
        // Load existing note
        editorProvider.loadNote(authState.currentUser!.uid, widget.noteId!);
      } else {
        // Initialize for new note
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
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthStateNotifier>();
      if (authState.currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      context.read<NoteEditorNotifier>().saveNote(
        userId: authState.currentUser!.uid,
        title: _titleController.text,
        body: _bodyController.text,
        imageUrl: _selectedImagePath,
      );

      widget.onSave?.call();
      Navigator.of(context).pop();
    }
  }

  void _handleDelete() {
    final editorProvider = context.read<NoteEditorNotifier>();
    final authState = context.read<AuthStateNotifier>();

    if (editorProvider.currentNote == null || authState.currentUser == null) {
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
                editorProvider.deleteNote(
                  authState.currentUser!.uid,
                  editorProvider.currentNote!.id,
                );
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
            Consumer<NoteEditorNotifier>(
              builder: (context, editorProvider, _) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: editorProvider.currentNote != null
                      ? _handleDelete
                      : null,
                );
              },
            ),
        ],
      ),
      body: Consumer<NoteEditorNotifier>(
        builder: (context, editorProvider, _) {
          // Loading state
          if (editorProvider.isLoading && editorProvider.currentNote == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message
                  if (editorProvider.errorMessage != null)
                    Padding(
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
                                editorProvider.errorMessage ?? '',
                                style: const TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

                  // Location info
                  LocationInfoWidget(
                    latitude: editorProvider.latitude,
                    longitude: editorProvider.longitude,
                    isLoading: editorProvider.isLocationLoading,
                    onRefresh: () {
                      editorProvider.updateLocation();
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),

                  // Image section
                  if (_selectedImagePath != null ||
                      editorProvider.currentNote?.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacingMd,
                      ),
                      child: ImagePreviewWidget(
                        imageUrl:
                            _selectedImagePath ??
                            editorProvider.currentNote?.imageUrl,
                        onRemove: () {
                          setState(() {
                            _selectedImagePath = null;
                          });
                        },
                      ),
                    ),

                  // Buttons
                  Row(
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
                          isLoading: editorProvider.isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
