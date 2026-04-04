import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/note.dart';
import 'note_card.dart';

class DraggableNote extends StatefulWidget {
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
  State<DraggableNote> createState() => _DraggableNoteState();
}

class _DraggableNoteState extends State<DraggableNote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtl;
  late final Animation<double> _scaleAnim;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _animCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.045,
    ).animate(CurvedAnimation(parent: _animCtl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtl.dispose();
    super.dispose();
  }

  void _onDragStart() {
    if (widget.note.pinned) return;
    setState(() => _dragging = true);
    _animCtl.forward();
    HapticFeedback.lightImpact();
  }

  void _onDragEnd() {
    if (!_dragging) return;
    setState(() => _dragging = false);
    _animCtl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final pinned = widget.note.pinned;

    return GestureDetector(
      onTap: widget.onView,
      onPanStart: pinned ? null : (_) => _onDragStart(),
      onPanUpdate: pinned
          ? null
          : (details) {
              final scale = widget.getScale().clamp(0.0001, 1e6);
              widget.onDrag(details.delta / scale);
            },
      onPanEnd: pinned ? null : (_) => _onDragEnd(),
      onPanCancel: pinned ? null : _onDragEnd,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: DecoratedBox(
            // Shadow appears only while dragging.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow: _dragging
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: child,
          ),
        ),
        child: NoteCard(note: widget.note, onTogglePin: widget.onTogglePin),
      ),
    );
  }
}
