import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class CanvasController {
  final TransformationController transformController =
      TransformationController();

  void setInitialView({
    required Size canvasSize,
    required Size viewportSize,
    double scale = 0.5, // <- choose your default zoom here
    Offset? focus,
  }) {
    final s = scale.clamp(0.01, 100.0);
    final cx = (focus?.dx) ?? (canvasSize.width / 2);
    final cy = (focus?.dy) ?? (canvasSize.height / 2);

    final tx = viewportSize.width / 2 - s * cx;
    final ty = viewportSize.height / 2 - s * cy;

    transformController.value = Matrix4.compose(
      Vector3(tx, ty, 0),
      Quaternion.identity(),
      Vector3(scale, scale, 1),
    );
  }

  void zoomToRect(BuildContext context, Rect rect) {
    final size = MediaQuery.of(context).size;
    final sx = size.width / rect.width;
    final sy = size.height / rect.height;
    final s = (sx < sy ? sx : sy);
    final cx = rect.left + rect.width / 2;
    final cy = rect.top + rect.height / 2;
    setInitialView(
      canvasSize: Size.infinite,
      viewportSize: size,
      scale: s,
      focus: Offset(cx, cy),
    );
  }
}
