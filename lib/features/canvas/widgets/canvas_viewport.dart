import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/features/canvas/canvas_controller.dart';
import 'package:gk_notes/features/canvas/widgets/create_note_dialog.dart';
import 'package:gk_notes/features/canvas/widgets/draggable_note.dart';
import 'package:gk_notes/features/canvas/widgets/grid_painter.dart';
import '../../../../data/models/note.dart';

const Size kDefaultNoteSize = Size(
  200,
  140,
); // must match your addAt() size in provider.dart

class CanvasViewport extends ConsumerWidget {
  const CanvasViewport({
    super.key,
    required this.controller,
    required this.canvasSize,
    required this.notes,
    required this.onAddAt,
    required this.onMove,
    required this.onEdit,
  });

  final CanvasController controller;
  final Size canvasSize;
  final List<Note> notes;

  final Future<void> Function(
    Offset pos, {
    required String title,
    required String text,
  })
  onAddAt;

  final void Function(String id, Offset delta) onMove;
  final ValueChanged<Note> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (d) async {
        // screen -> scene
        final inv = controller.transformController.value.clone()..invert();
        final scenePoint = MatrixUtils.transformPoint(inv, d.localPosition);

        // ask for title + body
        final created = await showCreateNoteDialog(context);
        if (created == null) return;

        // clamp inside canvas
        final clamped = Offset(
          scenePoint.dx.clamp(0, canvasSize.width - kDefaultNoteSize.width),
          scenePoint.dy.clamp(0, canvasSize.height - kDefaultNoteSize.height),
        );

        await onAddAt(clamped, title: created.title, text: created.text);
      },
      child: InteractiveViewer(
        transformationController: controller.transformController,
        constrained: false,
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        minScale: 0.25,
        maxScale: 12,
        boundaryMargin: const EdgeInsets.all(50000),
        child: SizedBox(
          width: canvasSize.width,
          height: canvasSize.height,
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: controller.transformController,
                  builder: (_, __) {
                    final scale = controller.transformController.value
                        .getMaxScaleOnAxis();
                    return CustomPaint(
                      painter: GridPainter(
                        spacing: 64,
                        majorEvery: 14,
                        scale: scale,
                      ),
                    );
                  },
                ),
              ),
              for (final n in notes)
                Positioned(
                  left: n.pos.dx,
                  top: n.pos.dy,
                  child: DraggableNote(
                    note: n,
                    onEdit: () => onEdit(n),
                    onDrag: (delta) {
                      final newPos = n.pos + delta;

                      final clampedX = newPos.dx.clamp(
                        0,
                        canvasSize.width - n.size.width,
                      );
                      final clampedY = newPos.dy.clamp(
                        0,
                        canvasSize.height - n.size.height,
                      );

                      // convert back to a delta from the current position
                      final clampedDelta = Offset(
                        clampedX - n.pos.dx,
                        clampedY - n.pos.dy,
                      );

                      onMove(n.id, clampedDelta);
                    },
                    getScale: () => controller.transformController.value
                        .getMaxScaleOnAxis(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
