import 'package:flutter/material.dart';

/// App-wide note colors (order matters for pickers).
const kNoteColors = <Color>[
  Color(0xFF38464F), // BlueGrey (your current default)
  Color(0xFF294D6B), // Muted Blue
  Color(0xFF6B5B2D), // Muted Amber/Bronze
  Color(0xFF2F5B4A), // Muted Teal/Green
  Color(0xFF6B2E33), // Muted Red
  Color(0xFF50335F), // Muted Purple
  Color(0xFF4A5B2F), // Deep Olive
  Color.fromARGB(255, 71, 54, 21),
];

/// Find the index of a color value inside [kNoteColors]. Returns 0 if not found.
int noteColorIndexOf(int colorValue) {
  final i = kNoteColors.indexWhere((c) => c.value == colorValue);
  return i >= 0 ? i : 0;
}
