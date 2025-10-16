import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note});
  final Note note;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: note.size.width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty)
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            if (note.title.isNotEmpty) const SizedBox(height: 4),
            Text(
              note.text,
              maxLines: null,
              overflow: TextOverflow.visible,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
