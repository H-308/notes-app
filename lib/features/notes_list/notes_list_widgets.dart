import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/models/note.dart';

/// Note item card widget
/// Always const to prevent unnecessary rebuilds when parent rebuilds
class NoteItemCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onLongPress;

  const NoteItemCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onDeleteTap,
    this.onLongPress,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy - h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      note.title,
                      style: AppTheme.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),

                    // Body preview
                    Text(
                      note.body,
                      style: AppTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Image preview if exists
                    if (note.imageBase64 != null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 16,
                              color: AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: AppTheme.spacingSm),
                            Text('Image attached', style: AppTheme.bodySmall),
                          ],
                        ),
                      ),

                    // Footer with location and date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${note.latitude.toStringAsFixed(4)}, ${note.longitude.toStringAsFixed(4)}',
                                  style: AppTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(note.createdAt),
                          style: AppTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              if (onDeleteTap != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onDeleteTap,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyNotesWidget extends StatelessWidget {
  final VoidCallback onCreateTap;

  const EmptyNotesWidget({super.key, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 80,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No notes yet. Click the + button to create one!',
              style: AppTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error widget
class NotesErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const NotesErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
