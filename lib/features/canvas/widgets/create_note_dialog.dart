import 'package:flutter/material.dart';
import 'package:gk_notes/theme/note_colors.dart';

class CreateNoteResult {
  final String title;
  final String text;
  final int colorValue;
  const CreateNoteResult(this.title, this.text, this.colorValue);
}

Future<CreateNoteResult?> showCreateNoteDialog(BuildContext context) async {
  final titleCtl = TextEditingController();
  final bodyCtl = TextEditingController();
  int selected = 0;

  final res = await showDialog<CreateNoteResult>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);

      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
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
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                  child: Text(
                    'Färg',
                    style: Theme.of(ctx).textTheme.labelLarge,
                  ),
                ),
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
                  onPressed: () {
                    Navigator.pop(
                      ctx,
                      CreateNoteResult(
                        titleCtl.text.trim(),
                        bodyCtl.text,
                        kNoteColors[selected].value,
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color?>(
                      Colors.blueGrey[800],
                    ),
                  ),
                  child: const Text(
                    'Skapa',
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

  return res;
}
