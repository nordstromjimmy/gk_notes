import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/features/canvas/canvas_page.dart';
import 'core/theme.dart';

class NotesCanvasApp extends StatelessWidget {
  const NotesCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'SpaceNotes',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const CanvasPage(),
      ),
    );
  }
}
