// lib/features/canvas/widgets/view_note_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/note.dart';
import 'edit_note_dialog.dart';

enum _ViewAction { close, edit }

Future<NoteEditOutcome?> showViewNoteDialog({
  required BuildContext context,
  required Note note,
  AddImagesFn? onAddImages,
  RemoveImageFn? onRemoveImage,
}) async {
  final action = await showDialog<_ViewAction>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);
      const bg = Color(0xFF38464F);
      const fgMuted = Colors.white70;

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        backgroundColor: bg,
        scrollable: true,
        title: Row(
          children: [
            const Text(
              'Anteckning',
              style: TextStyle(color: fgMuted, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Redigera',
              icon: const Icon(Icons.settings_outlined, color: fgMuted),
              onPressed: () => Navigator.pop(ctx, _ViewAction.edit),
            ),
          ],
        ),
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: fgMuted,
                  ),
                ),
              if (note.title.isNotEmpty) const SizedBox(height: 12),
              Text(
                note.text,
                style: const TextStyle(color: fgMuted, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // --- Images (thumbnails + tap to preview) ---
              if (note.imagePaths.isNotEmpty) ...[
                Text(
                  'Bilder',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelLarge?.copyWith(color: fgMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: note.imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = note.imagePaths[i];
                      return GestureDetector(
                        onTap: () => _showImageViewer(
                          context,
                          note.imagePaths,
                          initialIndex: i,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(p),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 96,
                              height: 96,
                              color: Colors.black26,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, _ViewAction.close),
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    Colors.blueGrey,
                  ),
                ),
                child: const Text(
                  'Stäng',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (action != _ViewAction.edit) return null;

  // Forward to the edit dialog (which can also add/remove images)
  return showEditNoteDialog(
    context: context,
    note: note,
    onAddImages: onAddImages,
    onRemoveImage: onRemoveImage,
  );
}

/// Full-screen, swipeable, pinch-zoom image viewer
void _showImageViewer(
  BuildContext context,
  List<String> paths, {
  int initialIndex = 0,
}) {
  final controller = PageController(initialPage: initialIndex);
  showDialog(
    context: context,
    barrierColor: Colors.black..withValues(alpha: 0.9),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: paths.length,
            itemBuilder: (_, i) {
              final file = File(paths[i]);
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
