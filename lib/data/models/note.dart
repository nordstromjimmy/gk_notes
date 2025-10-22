// lib/data/models/note.dart
import 'package:flutter/material.dart';

class Note {
  // Public ID (UUID)
  late String id;

  // Content
  late String title;
  late String text;

  // Canvas geometry
  late double x;
  late double y;
  late double w;
  late double h;

  // Styling
  late int colorValue;

  // State
  bool pinned = false;

  // Media and files
  List<String> imagePaths = const [];
  List<String> videoPaths = const [];
  List<String> videoThumbPaths = const [];
  List<String> pdfPaths = const [];

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
    required this.title,
    required this.text,
    required Offset pos,
    required Size size,
    required this.colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : x = pos.dx,
       y = pos.dy,
       w = size.width,
       h = size.height,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? id,
    String? title,
    String? text,
    Offset? pos,
    Size? size,
    int? colorValue,
    bool? pinned,
    List<String>? imagePaths,
    List<String>? videoPaths,
    List<String>? videoThumbPaths,
    List<String>? pdfPaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final n = Note();
    n.id = id ?? this.id;
    n.title = title ?? this.title;
    n.text = text ?? this.text;
    final p = pos ?? Offset(x, y);
    final s = size ?? Size(w, h);
    n.x = p.dx;
    n.y = p.dy;
    n.w = s.width;
    n.h = s.height;
    n.colorValue = colorValue ?? this.colorValue;
    n.pinned = pinned ?? this.pinned;
    n.imagePaths = imagePaths ?? this.imagePaths;
    n.videoPaths = videoPaths ?? this.videoPaths;
    n.videoThumbPaths = videoThumbPaths ?? this.videoThumbPaths;
    n.pdfPaths = pdfPaths ?? this.pdfPaths;
    n.createdAt = createdAt ?? this.createdAt;
    n.updatedAt = updatedAt ?? this.updatedAt;
    return n;
  }

  // ----- persistence helpers (JSON-ready) -----
  Map<String, dynamic> toExportJson() => {
    'id': id,
    'title': title,
    'text': text,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'color': colorValue,
    'pinned': pinned,
    'images': imagePaths,
    'videos': videoPaths,
    'videoThumbs': videoThumbPaths,
    'pdfPaths': pdfPaths,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static Note fromImportJson(Map<String, dynamic> j) {
    final n = Note();
    n.id = j['id'] as String;
    n.title = j['title'] as String;
    n.text = j['text'] as String? ?? '';
    n.x = (j['x'] as num).toDouble();
    n.y = (j['y'] as num).toDouble();
    n.w = (j['w'] as num).toDouble();
    n.h = (j['h'] as num).toDouble();
    n.colorValue = (j['color'] as num).toInt();
    n.pinned = (j['pinned'] as bool?) ?? false;
    n.imagePaths = (j['images'] as List?)?.cast<String>() ?? const [];
    n.videoPaths = (j['videos'] as List?)?.cast<String>() ?? const [];
    n.videoThumbPaths = (j['videoThumbs'] as List?)?.cast<String>() ?? const [];
    n.pdfPaths = (j['pdfPaths'] as List?)?.cast<String>() ?? const [];
    n.createdAt = DateTime.parse(j['createdAt'] as String);
    n.updatedAt = DateTime.parse(j['updatedAt'] as String);
    return n;
  }
}
