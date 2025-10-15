import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteEditOutcome {
  final String? newTitle;
  final String? newText;
  final bool deleted;
  const NoteEditOutcome({this.newTitle, this.newText, this.deleted = false});
}

Future<NoteEditOutcome?> showEditNoteDialog({
  required BuildContext context,
  required Note note,
}) async {
  final titleCtl = TextEditingController(text: note.title);
  final bodyCtl = TextEditingController(text: note.text);

  final result = await showDialog<_InternalResult>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);

      return AlertDialog(
        // Make the dialog use more horizontal space
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        scrollable: true, // allows tall content to scroll if needed

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
                          Spacer(),
                          FilledButton.tonal(
                            onPressed: () => Navigator.pop(c2, true),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll<Color?>(
                                Colors.blueGrey[800],
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
        // Give the dialog a wider body
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  _InternalResult.save(titleCtl.text.trim(), bodyCtl.text),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color?>(
                    Colors.blueGrey[800],
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
  );
}

class _InternalResult {
  final String? title;
  final String? text;
  final bool deleted;
  const _InternalResult._(this.title, this.text, this.deleted);
  const _InternalResult.delete() : this._(null, null, true);
  const _InternalResult.save(String t, String b) : this._(t, b, false);
}
