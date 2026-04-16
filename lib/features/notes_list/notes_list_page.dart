import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/features/notes_list/notes_list_provider.dart';
import 'package:notes_app/features/notes_list/notes_list_widgets.dart';
import 'package:notes_app/models/note.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      context.read<NotesListNotifier>().initializeNotes();
    });
  }

  void _handleDeleteNote(String noteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<NotesListNotifier>().deleteNote(noteId);
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

  void _scheduleWelcomeDialog() {
    final notesNotifier = context.read<NotesListNotifier>();
    if (!notesNotifier.shouldShowWelcomeDialog) return;

    notesNotifier.consumeWelcomeDialogTrigger();

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'User';

    // מציגים את הדיאלוג
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome!'),
          content: Text('Connected as: $email'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
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
        title: const Text('My Notes'),
        elevation: 0,
        centerTitle: true,
      ),
      body:
          Selector<
            NotesListNotifier,
            (List<Note>, bool, bool, String?, bool, bool, bool)
          >(
            selector: (context, provider) => (
              provider.notes,
              provider.isLoading,
              provider.isEmpty,
              provider.errorMessage,
              provider.isInitialAuthCheck,
              provider.shouldShowErrorUi,
              provider.shouldShowWelcomeDialog,
            ),
            builder: (context, state, _) {
              final (
                notes,
                isLoading,
                isEmpty,
                errorMessage,
                isInitialAuthCheck,
                shouldShowErrorUi,
                shouldShowWelcomeDialog,
              ) = state;

              if (shouldShowWelcomeDialog) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scheduleWelcomeDialog(),
                );
              }

              if (isLoading && notes.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (errorMessage != null &&
                  shouldShowErrorUi &&
                  !isInitialAuthCheck) {
                return NotesErrorWidget(
                  message: errorMessage,
                  onRetry: () =>
                      context.read<NotesListNotifier>().initializeNotes(),
                );
              }

              if (isLoading || isInitialAuthCheck) {
                return const Center(child: CircularProgressIndicator());
              }

              if (notes.isEmpty) {
                return EmptyNotesWidget(
                  onCreateTap: widget.onCreateNote ?? () {},
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<NotesListNotifier>().initializeNotes();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return _NoteItemTile(
                      note: note,
                      onTap: () {
                        widget.onNoteSelected?.call(note.id);
                      },
                      onDeleteTap: () {
                        _handleDeleteNote(note.id);
                      },
                    );
                  },
                ),
              );
            },
          ),
    );
  }
}

class _NoteItemTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  const _NoteItemTile({
    required this.note,
    required this.onTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: NoteItemCard(note: note, onTap: onTap, onDeleteTap: onDeleteTap),
    );
  }
}
