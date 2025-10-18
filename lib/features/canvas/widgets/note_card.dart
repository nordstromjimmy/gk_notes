import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, this.onTogglePin});

  final Note note;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    const hPad = 8.0; // horizontal padding
    const vPad = 6.0; // vertical padding
    const gapT = 4.0; // gap between title and body
    const iconSize = 16.0;

    final hasTitle = note.title.isNotEmpty;
    final hasText = note.text.isNotEmpty;

    return RepaintBoundary(
      child: Container(
        width: note.size.width,
        padding: const EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white70, height: 1.2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasTitle ? note.title : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (note.imagePaths.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.image,
                        size: iconSize,
                        color: Colors.white70,
                      ),
                    ),
                  IconButton(
                    onPressed: onTogglePin,
                    tooltip: note.pinned ? 'Unpin' : 'Pin',
                    icon: Icon(
                      note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: iconSize,
                    ),
                    color: Colors.white70,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 28,
                      height: 28,
                    ),
                    splashRadius: 16,
                  ),
                ],
              ),

              if (hasTitle && hasText) const SizedBox(height: gapT),

              if (hasText)
                Text(
                  note.text,
                  maxLines: 12,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
