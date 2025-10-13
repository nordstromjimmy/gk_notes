import 'package:flutter/widgets.dart';

class CanvasCamera {
  final Matrix4 transform;
  const CanvasCamera(this.transform);

  CanvasCamera copyWith({Matrix4? transform}) =>
      CanvasCamera(transform ?? this.transform);
}
