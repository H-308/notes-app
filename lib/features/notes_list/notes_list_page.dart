import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/features/auth/auth_provider.dart';
import 'package:notes_app/features/notes_list/notes_list_provider.dart';
import 'package:notes_app/features/notes_list/notes_list_widgets.dart';

/// Notes list page
class NotesListPage extends StatefulWidget {
  final VoidCallback? onCreateNote;
  final Function(String noteId)? onNoteSelected;

  const NotesListPage({super.key, this.onCreateNote, this.onNoteSelected});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthStateNotifier>();
      if (authState.currentUser != null) {
        context.read<NotesListNotifier>().initializeNotes(
          authState.currentUser!.uid,
        );
      }
    });
  }

  void _handleDeleteNote(String noteId) {
    final authState = context.read<AuthStateNotifier>();
    if (authState.currentUser != null) {
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
                  context.read<NotesListNotifier>().deleteNote(
                    authState.currentUser!.uid,
                    noteId,
                  );
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<NotesListNotifier>(
        builder: (context, notesListProvider, _) {
          // Loading state
          if (notesListProvider.isLoading && notesListProvider.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (notesListProvider.errorMessage != null) {
            return NotesErrorWidget(
              message: notesListProvider.errorMessage ?? 'Unknown error',
              onRetry: () {
                final authState = context.read<AuthStateNotifier>();
                if (authState.currentUser != null) {
                  context.read<NotesListNotifier>().initializeNotes(
                    authState.currentUser!.uid,
                  );
                }
              },
            );
          }

          // Empty state
          if (notesListProvider.isEmpty) {
            return EmptyNotesWidget(onCreateTap: widget.onCreateNote ?? () {});
          }

          // Notes list
          return RefreshIndicator(
            onRefresh: () async {
              final authState = context.read<AuthStateNotifier>();
              if (authState.currentUser != null) {
                context.read<NotesListNotifier>().initializeNotes(
                  authState.currentUser!.uid,
                );
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              itemCount: notesListProvider.notes.length,
              itemBuilder: (context, index) {
                final note = notesListProvider.notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                  child: NoteItemCard(
                    note: note,
                    onTap: () {
                      widget.onNoteSelected?.call(note.id);
                    },
                    onDeleteTap: () {
                      _handleDeleteNote(note.id);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
