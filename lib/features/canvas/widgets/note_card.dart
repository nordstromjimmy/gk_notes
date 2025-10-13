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
        child: Text(
          note.text,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
