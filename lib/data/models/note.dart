import 'package:flutter/material.dart';

class Note {
  final String id;
  final String title;
  final String text;
  final double x;
  final double y;
  final double w;
  final double h;
  final int colorValue;
  final bool pinned;
  final List<String> imagePaths;
  final List<String> videoPaths;
  final List<String> videoThumbPaths;
  final List<String> pdfPaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.text,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.colorValue,
    this.pinned = false,
    this.imagePaths = const [],
    this.videoPaths = const [],
    this.videoThumbPaths = const [],
    this.pdfPaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Note.create({
    required String id,
    required String title,
    required String text,
    required Offset pos,
    required Size size,
    required int colorValue,
    bool pinned = false,
    List<String> imagePaths = const [],
    List<String> videoPaths = const [],
    List<String> videoThumbPaths = const [],
    List<String> pdfPaths = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : this(
         id: id,
         title: title,
         text: text,
         x: pos.dx,
         y: pos.dy,
         w: size.width,
         h: size.height,
         colorValue: colorValue,
         pinned: pinned,
         imagePaths: imagePaths,
         videoPaths: videoPaths,
         videoThumbPaths: videoThumbPaths,
         pdfPaths: pdfPaths,
         createdAt: createdAt ?? DateTime.now(),
         updatedAt: updatedAt ?? DateTime.now(),
       );

  Offset get pos => Offset(x, y);
  Size get size => Size(w, h);
  Color get color => Color(colorValue);

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
    final p = pos ?? Offset(x, y);
    final s = size ?? Size(w, h);
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      x: p.dx,
      y: p.dy,
      w: s.width,
      h: s.height,
      colorValue: colorValue ?? this.colorValue,
      pinned: pinned ?? this.pinned,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPaths: videoPaths ?? this.videoPaths,
      videoThumbPaths: videoThumbPaths ?? this.videoThumbPaths,
      pdfPaths: pdfPaths ?? this.pdfPaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---- Hive storage (internal format, can evolve freely) ----

  Map<String, dynamic> toHiveMap() => {
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

  /// Returns null if [map] is missing required fields, rather than throwing.
  static Note? tryFromHiveMap(Map<String, dynamic> map) {
    try {
      return Note(
        id: map['id'] as String,
        title: map['title'] as String? ?? '',
        text: map['text'] as String? ?? '',
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        w: (map['w'] as num).toDouble(),
        h: (map['h'] as num).toDouble(),
        colorValue: (map['color'] as num).toInt(),
        pinned: (map['pinned'] as bool?) ?? false,
        imagePaths: (map['images'] as List?)?.cast<String>() ?? const [],
        videoPaths: (map['videos'] as List?)?.cast<String>() ?? const [],
        videoThumbPaths:
            (map['videoThumbs'] as List?)?.cast<String>() ?? const [],
        pdfPaths: (map['pdfPaths'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  // ---- User-facing export/import (stable public format) ----
  // Keep field names here stable — changing them breaks existing export files.

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

  factory Note.fromImportJson(Map<String, dynamic> j) => Note(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    text: j['text'] as String? ?? '',
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    w: (j['w'] as num).toDouble(),
    h: (j['h'] as num).toDouble(),
    colorValue: (j['color'] as num).toInt(),
    pinned: (j['pinned'] as bool?) ?? false,
    imagePaths: (j['images'] as List?)?.cast<String>() ?? const [],
    videoPaths: (j['videos'] as List?)?.cast<String>() ?? const [],
    videoThumbPaths: (j['videoThumbs'] as List?)?.cast<String>() ?? const [],
    pdfPaths: (j['pdfPaths'] as List?)?.cast<String>() ?? const [],
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
  );
}

/// Default size for newly created notes.
/// Single source of truth — used by both CanvasViewport and NotesNotifier.
const Size kDefaultNoteSize = Size(200, 140);
