import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final double spacing;
  final int majorEvery;
  GridPainter({this.spacing = 64, this.majorEvery = 4});

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1.2;
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
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      oldDelegate.spacing != spacing || oldDelegate.majorEvery != majorEvery;
}
