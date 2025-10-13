// lib/data/models/note.dart
import 'package:flutter/material.dart';

class Note {
  // Public ID (UUID)
  late String id;

  // Content
  late String text;

  // Canvas geometry
  late double x;
  late double y;
  late double w;
  late double h;

  // Styling
  late int colorValue;

  // Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  // ---- UI helpers (non-persisted) ----
  Offset get pos => Offset(x, y);
  Size get size => Size(w, h);
  Color get color => Color(colorValue);

  // Empty constructor for manual fills / fromJson
  Note();

  // Convenience creator
  Note.create({
    required this.id,
    required String text,
    required Offset pos,
    required Size size,
    required int colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : text = text,
       x = pos.dx,
       y = pos.dy,
       w = size.width,
       h = size.height,
       colorValue = colorValue,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? id,
    String? text,
    Offset? pos,
    Size? size,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final n = Note();
    n.id = id ?? this.id;
    n.text = text ?? this.text;
    final p = pos ?? Offset(x, y);
    final s = size ?? Size(w, h);
    n.x = p.dx;
    n.y = p.dy;
    n.w = s.width;
    n.h = s.height;
    n.colorValue = colorValue ?? this.colorValue;
    n.createdAt = createdAt ?? this.createdAt;
    n.updatedAt = updatedAt ?? this.updatedAt;
    return n;
  }

  // ----- persistence helpers (JSON-ready) -----
  Map<String, dynamic> toExportJson() => {
    'id': id,
    'text': text,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'color': colorValue,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Note fromImportJson(Map<String, dynamic> j) {
    final n = Note();
    n.id = j['id'] as String;
    n.text = j['text'] as String? ?? '';
    n.x = (j['x'] as num).toDouble();
    n.y = (j['y'] as num).toDouble();
    n.w = (j['w'] as num).toDouble();
    n.h = (j['h'] as num).toDouble();
    n.colorValue = (j['color'] as num).toInt();
    n.createdAt = DateTime.parse(j['createdAt'] as String);
    n.updatedAt = DateTime.parse(j['updatedAt'] as String);
    return n;
  }
}
