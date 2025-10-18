import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gk_notes/theme/note_colors.dart';
import '../../../data/models/note.dart';

class NoteEditOutcome {
  final String? newTitle;
  final String? newText;
  final int? newColorValue;
  final bool deleted;
  const NoteEditOutcome({
    this.newTitle,
    this.newText,
    this.newColorValue,
    this.deleted = false,
  });
}

/// Optional callbacks let the dialog update images without depending on Riverpod.
/// Each callback should return the **updated list of image paths** for the note.
typedef AddImagesFn = Future<List<String>> Function(String noteId);
typedef RemoveImageFn =
    Future<List<String>> Function(String noteId, String path);

Future<NoteEditOutcome?> showEditNoteDialog({
  required BuildContext context,
  required Note note,
  AddImagesFn? onAddImages, // <-- NEW (optional)
  RemoveImageFn? onRemoveImage, // <-- NEW (optional)
}) async {
  final titleCtl = TextEditingController(text: note.title);
  final bodyCtl = TextEditingController(text: note.text);

  final result = await showDialog<_InternalResult>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);

      int selected = noteColorIndexOf(note.colorValue);
      // Local, live image list inside the dialog (so UI can refresh instantly)
      List<String> images = List<String>.from(note.imagePaths);

      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          scrollable: true,

          title: Row(
            children: [
              const Text('Redigera'),
              const Spacer(),
              IconButton(
                tooltip: 'Radera',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final sure = await showDialog<bool>(
                    context: ctx,
                    builder: (c2) => AlertDialog(
                      title: const Text('Radera?'),
                      content: const Text('Vill du radera denna anteckning?'),
                      actions: [
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(c2, false),
                              child: const Text(
                                'Avbryt',
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ),
                            const Spacer(),
                            FilledButton.tonal(
                              onPressed: () => Navigator.pop(c2, true),
                              style: const ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll<Color>(
                                  Colors.blueGrey,
                                ),
                              ),
                              child: const Text(
                                'Radera',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  if (sure == true) {
                    Navigator.pop(ctx, const _InternalResult.delete());
                  }
                },
              ),
            ],
          ),

          content: SizedBox(
            width: dialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: titleCtl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Titel',
                    hintText: 'Skriv en titel…',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Body
                TextField(
                  controller: bodyCtl,
                  minLines: 3,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Text',
                    hintText: 'Skriv din anteckning…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Color picker
                Text('Färg', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < kNoteColors.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => selected = i),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kNoteColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: selected == i ? 2 : 1,
                              color: selected == i
                                  ? Colors.black87
                                  : Colors.black26,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Images section
                Row(
                  children: [
                    Text('Bilder', style: Theme.of(ctx).textTheme.labelLarge),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: (onAddImages == null)
                          ? null
                          : () async {
                              final updated = await onAddImages(note.id);
                              setState(() => images = updated);
                            },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Lägg till'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = images[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(p),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 90,
                                height: 90,
                                color: Colors.black26,
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              tooltip: 'Ta bort',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.black87,
                              onPressed: (onRemoveImage == null)
                                  ? null
                                  : () async {
                                      final updated = await onRemoveImage(
                                        note.id,
                                        p,
                                      );
                                      setState(() => images = updated);
                                    },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          actions: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Avbryt',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    _InternalResult.save(
                      titleCtl.text.trim(),
                      bodyCtl.text,
                      kNoteColors[selected].value,
                    ),
                  ),
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.blueGrey,
                    ),
                  ),
                  child: const Text(
                    'Spara',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  if (result == null) return null; // cancelled
  if (result.deleted) return const NoteEditOutcome(deleted: true);

  final t = result.title;
  final b = result.text;
  return NoteEditOutcome(
    newTitle: t != note.title ? t : null,
    newText: b != note.text ? b : null,
    newColorValue: result.colorValue != note.colorValue
        ? result.colorValue
        : null,
  );
}

class _InternalResult {
  final String? title;
  final String? text;
  final int? colorValue;
  final bool deleted;
  const _InternalResult._(this.title, this.text, this.colorValue, this.deleted);
  const _InternalResult.delete() : this._(null, null, null, true);
  const _InternalResult.save(String t, String b, int c)
    : this._(t, b, c, false);
}
