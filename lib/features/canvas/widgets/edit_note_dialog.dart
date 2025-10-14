import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteEditOutcome {
  final String? newText;
  final bool deleted;
  const NoteEditOutcome({this.newText, this.deleted = false});
}

Future<NoteEditOutcome?> showEditNoteDialog({
  required BuildContext context,
  required Note note,
}) async {
  final ctl = TextEditingController(text: note.text);

  final result = await showDialog<_InternalResult>(
    context: context,
    builder: (ctx) => AlertDialog(
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
                    TextButton(
                      onPressed: () => Navigator.pop(c2, false),
                      child: const Text('Avbryt'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.pop(c2, true),
                      child: const Text('Radera'),
                    ),
                  ],
                ),
              );
              if (sure == true)
                Navigator.pop(ctx, const _InternalResult.delete());
            },
          ),
        ],
      ),
      content: TextField(
        minLines: 3,
        maxLines: 10,
        controller: ctl,
        autofocus: false,
        decoration: const InputDecoration(hintText: ''),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _InternalResult.save(ctl.text)),
          child: const Text('Spara'),
        ),
      ],
    ),
  );

  if (result == null) return null; // cancelled
  if (result.deleted) return const NoteEditOutcome(deleted: true);
  return NoteEditOutcome(newText: result.text);
}

class _InternalResult {
  final String? text;
  final bool deleted;
  const _InternalResult._(this.text, this.deleted);
  const _InternalResult.delete() : this._(null, true);
  const _InternalResult.save(String t) : this._(t, false);
}
