import 'package:flutter/material.dart';
import '../../../data/models/note.dart';
import 'note_card.dart';

class DraggableNote extends StatelessWidget {
  const DraggableNote({
    super.key,
    required this.note,
    required this.onView,
    required this.onDrag,
    required this.getScale,
    this.onTogglePin,
  });

  final Note note;
  final VoidCallback onView;
  final ValueChanged<Offset> onDrag;
  final double Function() getScale;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final pinned = note.pinned;

    return GestureDetector(
      onTap: onView,
      onPanUpdate: pinned
          ? null
          : (details) {
              final scale = getScale().clamp(0.0001, 1e6);
              onDrag(details.delta / scale);
            },
      child: NoteCard(note: note, onTogglePin: onTogglePin),
    );
  }
}
