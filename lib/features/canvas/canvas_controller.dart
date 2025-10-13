import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class CanvasController {
  final TransformationController transformController =
      TransformationController();

  Offset globalToCanvas(Offset globalPoint) {
    final inv = Matrix4.inverted(transformController.value);
    final vector = Vector3(globalPoint.dx, globalPoint.dy, 0);
    final r = inv.transform3(vector);
    return Offset(r.x, r.y);
  }

  void zoomToRect(BuildContext context, Rect rect, {double padding = 24}) {
    final viewport = MediaQuery.of(context).size;
    final scaleX = (viewport.width - padding * 2) / rect.width;
    final scaleY = (viewport.height - padding * 2) / rect.height;
    final targetScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.25, 4.0);

    final next = Matrix4.identity()
      ..scale(targetScale)
      ..translate(
        -(rect.left -
            (viewport.width / targetScale - rect.width) / 2 -
            padding),
        -(rect.top -
            (viewport.height / targetScale - rect.height) / 2 -
            padding),
      );

    transformController.value = next;
  }
}
