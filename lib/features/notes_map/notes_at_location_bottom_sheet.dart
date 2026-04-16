import 'package:flutter/material.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/models/note.dart';

/// Bottom sheet for displaying multiple notes at the same location
class NotesAtLocationBottomSheet extends StatelessWidget {
  final List<Note> notes;
  final Function(String noteId)? onNoteTapped;
  final VoidCallback? onClose;

  const NotesAtLocationBottomSheet({
    super.key,
    required this.notes,
    this.onNoteTapped,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 24),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    '${notes.length} note${notes.length > 1 ? 's' : ''} at this location',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          // Notes list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              itemCount: notes.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: AppTheme.spacingMd,
                endIndent: AppTheme.spacingMd,
              ),
              itemBuilder: (context, index) {
                final note = notes[index];
                return NoteListTile(
                  note: note,
                  onTap: () {
                    Navigator.of(context).pop();
                    onNoteTapped?.call(note.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Show the bottom sheet
  static void show(
    BuildContext context, {
    required List<Note> notes,
    Function(String noteId)? onNoteTapped,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          NotesAtLocationBottomSheet(notes: notes, onNoteTapped: onNoteTapped),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
    );
  }
}

/// List tile for displaying a single note
class NoteListTile extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteListTile({super.key, required this.note, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.note, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        note.title.isEmpty ? 'Untitled Note' : note.title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            note.body.isEmpty
                ? 'No description'
                : note.body.length > 60
                ? '${note.body.substring(0, 60)}...'
                : note.body,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${note.latitude.toStringAsFixed(4)}, Lng: ${note.longitude.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
