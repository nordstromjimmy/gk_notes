import 'package:flutter/material.dart';
import '../../../data/models/note.dart';
import 'note_card.dart';

class DraggableNote extends StatelessWidget {
  const DraggableNote({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDrag,
    required this.getScale,
  });
  final Note note;
  final VoidCallback onEdit;
  final ValueChanged<Offset> onDrag;
  final double Function() getScale; // read current zoom

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      onPanUpdate: (d) {
        final scale = getScale();
        onDrag(d.delta / scale);
      },
      child: NoteCard(note: note),
    );
  }
}
