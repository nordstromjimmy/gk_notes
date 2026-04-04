import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double spacing;
  final int majorEvery;
  final double scale;

  GridPainter({this.spacing = 64, this.majorEvery = 14, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = (1 / scale).clamp(0.5, 2.0)
      ..isAntiAlias = false;

    final major = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = (1.25 / scale).clamp(0.6, 2.5)
      ..isAntiAlias = false;

    // Integer step index avoids floating-point drift at large coordinates.
    // e.g. at x=9984.0, (9984/64).round() = 156, which is fine,
    // but accumulated double arithmetic can round incorrectly — int never does.
    final colCount = (size.width / spacing).ceil();
    final rowCount = (size.height / spacing).ceil();

    for (int i = 0; i <= colCount; i++) {
      final x = i * spacing;
      final paint = (i % majorEvery == 0) ? major : minor;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i <= rowCount; i++) {
      final y = i * spacing;
      final paint = (i % majorEvery == 0) ? major : minor;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) =>
      old.spacing != spacing ||
      old.majorEvery != majorEvery ||
      old.scale != scale;
}
