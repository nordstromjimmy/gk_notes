import 'package:flutter/material.dart';

class CreateNoteResult {
  final String title;
  final String text;
  const CreateNoteResult(this.title, this.text);
}

Future<CreateNoteResult?> showCreateNoteDialog(BuildContext context) async {
  final titleCtl = TextEditingController();
  final bodyCtl = TextEditingController();

  final res = await showDialog<CreateNoteResult>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        title: const Text('Ny anteckning'),
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                autofocus: true,
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                ctx,
                CreateNoteResult(titleCtl.text.trim(), bodyCtl.text),
              );
            },
            child: const Text('Skapa'),
          ),
        ],
      );
    },
  );

  return res;
}
