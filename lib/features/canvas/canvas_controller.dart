import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

class CanvasController {
  final TransformationController transformController =
      TransformationController();

  /// Centers the viewport on [focus] (defaults to the canvas centre) at [scale].
  /// This is the single source of truth for all programmatic camera moves.
  void setInitialView({
    required Size canvasSize,
    required Size viewportSize,
    double scale = 0.5,
    Offset? focus,
  }) {
    final s = scale.clamp(0.01, 100.0); // clamp once, use everywhere below
    final cx = focus?.dx ?? canvasSize.width / 2;
    final cy = focus?.dy ?? canvasSize.height / 2;

    final tx = viewportSize.width / 2 - s * cx;
    final ty = viewportSize.height / 2 - s * cy;

    transformController.value = Matrix4.compose(
      Vector3(tx, ty, 0),
      Quaternion.identity(),
      Vector3(s, s, 1), // was Vector3(scale, scale, 1) — bug fixed
    );
  }

  /// Convenience method used by canvas_page on first layout.
  /// Centers on the middle of [canvasSize] at [scale].
  void centerCanvas({
    required Size canvasSize,
    required Size viewportSize,
    double scale = 0.45,
  }) {
    setInitialView(
      canvasSize: canvasSize,
      viewportSize: viewportSize,
      scale: scale,
    );
  }

  /// Zooms and pans so that [rect] fills the viewport.
  void zoomToRect(BuildContext context, Rect rect) {
    final size = MediaQuery.of(context).size;
    final sx = size.width / rect.width;
    final sy = size.height / rect.height;
    final s = sx < sy ? sx : sy;
    setInitialView(
      canvasSize: Size.infinite,
      viewportSize: size,
      scale: s,
      focus: rect.center,
    );
  }
}
