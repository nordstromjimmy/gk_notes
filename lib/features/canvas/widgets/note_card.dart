import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, this.onTogglePin});
  final Note note;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: note.size.width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title.isNotEmpty ? note.title : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  tooltip: note.pinned ? 'Unpin' : 'Pin',
                  icon: Icon(
                    note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 18,
                    color: Colors.black87.withValues(
                      alpha: note.pinned ? 1 : 0.85,
                    ),
                  ),
                  onPressed: onTogglePin,
                ),
              ],
            ),
            if (note.title.isNotEmpty) const SizedBox(height: 4),
            if (note.text.isNotEmpty)
              Text(
                note.text,
                maxLines: 12,
                overflow: TextOverflow.visible,

                style: TextStyle(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}
