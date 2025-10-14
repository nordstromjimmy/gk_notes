import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double spacing;
  final int majorEvery;
  final double scale; // current zoom scale

  GridPainter({this.spacing = 64, this.majorEvery = 14, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Keep strokes ~1 logical pixel regardless of zoom
    final minor = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = (1 / scale).clamp(0.5, 2.0)
      ..isAntiAlias = false;

    final major = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = (1.25 / scale).clamp(0.6, 2.5)
      ..isAntiAlias = false;

    for (double x = 0; x <= size.width; x += spacing) {
      final isMajor = ((x / spacing).round() % majorEvery) == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? major : minor,
      );
    }
    for (double y = 0; y <= size.height; y += spacing) {
      final isMajor = ((y / spacing).round() % majorEvery) == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) =>
      old.spacing != spacing ||
      old.majorEvery != majorEvery ||
      old.scale != scale;
}
