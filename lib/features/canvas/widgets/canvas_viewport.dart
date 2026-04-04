import 'package:flutter/material.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:gk_notes/features/canvas/canvas_controller.dart';
import 'package:gk_notes/features/canvas/widgets/create_note_dialog.dart';
import 'package:gk_notes/features/canvas/widgets/draggable_note.dart';
import 'package:gk_notes/features/canvas/widgets/grid_painter.dart';
import '../../../../data/models/note.dart';

class CanvasViewport extends StatelessWidget {
  const CanvasViewport({
    super.key,
    required this.controller,
    required this.canvasSize,
    required this.notes,
    required this.onAddAt,
    required this.onMove,
    required this.onView,
    required this.onTogglePin,
  });

  final CanvasController controller;
  final Size canvasSize;
  final List<Note> notes;

  final Future<Note> Function(
    Offset pos, {
    required String title,
    required String text,
    int? colorValue,
    List<ImageToAttach>? images,
    List<String>? videos,
    List<String>? pdfs,
  })
  onAddAt;

  final void Function(String id, Offset delta) onMove;
  final ValueChanged<Note> onView;
  final ValueChanged<String> onTogglePin; // id of the note to toggle

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (d) async {
        // Convert screen coordinates to canvas coordinates.
        final inv = controller.transformController.value.clone()..invert();
        final scenePoint = MatrixUtils.transformPoint(inv, d.localPosition);

        final created = await showCreateNoteDialog(context);
        if (created == null) return;

        // Clamp so the note is fully inside the canvas.
        final clamped = Offset(
          scenePoint.dx.clamp(0, canvasSize.width - kDefaultNoteSize.width),
          scenePoint.dy.clamp(0, canvasSize.height - kDefaultNoteSize.height),
        );

        await onAddAt(
          clamped,
          title: created.title,
          text: created.text,
          colorValue: created.colorValue,
          images: created.images,
          videos: created.videoPaths,
          pdfs: created.pdfPaths,
        );
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
              // Grid — rebuilt only when the transform scale changes.
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

              // Notes — each wrapped in RepaintBoundary inside NoteCard.
              for (final n in notes)
                Positioned(
                  left: n.pos.dx,
                  top: n.pos.dy,
                  child: DraggableNote(
                    note: n,
                    onView: () => onView(n),
                    getScale: () => controller.transformController.value
                        .getMaxScaleOnAxis(),
                    onTogglePin: () => onTogglePin(n.id),
                    onDrag: (delta) {
                      final proposed = n.pos + delta;
                      final clampedDelta = Offset(
                        proposed.dx.clamp(0, canvasSize.width - n.size.width) -
                            n.pos.dx,
                        proposed.dy.clamp(
                              0,
                              canvasSize.height - n.size.height,
                            ) -
                            n.pos.dy,
                      );
                      onMove(n.id, clampedDelta);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
