import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, required this.highlighted});
  final Note note;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: note.size.width,
        height: note.size.height,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: highlighted ? 3 : 1,
            color: highlighted ? Colors.amber : Colors.black12,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
              color: Colors.black12,
            ),
          ],
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
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
