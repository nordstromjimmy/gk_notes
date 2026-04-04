import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:gk_notes/features/canvas/widgets/canvas_viewport.dart';
import 'package:gk_notes/features/canvas/widgets/view_note_dialog.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/note.dart';
import '../search/search_bar.dart';
import 'canvas_controller.dart';
import 'providers.dart';

class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({super.key});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  final CanvasController _canvas = CanvasController();
  final Size _canvasSize = const Size(20000, 20000);

  // True until the notifier's _init() delivers its first state update,
  // whether that's an empty list or a full list of notes.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canvas.centerCanvas(
        canvasSize: _canvasSize,
        viewportSize: MediaQuery.of(context).size,
        scale: 0.45,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    // First state update from the notifier signals that _init() has finished.
    ref.listen<List<Note>>(notesProvider, (_, __) {
      if (_loading) setState(() => _loading = false);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Notes'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'export') await _export();
              if (v == 'import') await _import();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_upload),
                  title: Text('Exportera JSON'),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Importera JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey[800],
        onPressed: _openSearchSheet,
        child: const Icon(Icons.search, color: Colors.white),
      ),
      body: Stack(
        children: [
          CanvasViewport(
            controller: _canvas,
            canvasSize: _canvasSize,
            notes: notes,
            onAddAt:
                (
                  pos, {
                  required title,
                  required text,
                  int? colorValue,
                  List<ImageToAttach>? images,
                  List<String>? videos,
                  List<String>? pdfs,
                }) async {
                  final newNote = await ref
                      .read(notesProvider.notifier)
                      .addAt(
                        pos,
                        title: title,
                        text: text,
                        colorValue: colorValue,
                      );
                  if (images != null && images.isNotEmpty) {
                    await ref
                        .read(notesProvider.notifier)
                        .attachImagesFromBytes(newNote.id, images);
                  }
                  if (videos != null && videos.isNotEmpty) {
                    await ref
                        .read(notesProvider.notifier)
                        .attachVideosFromPaths(newNote.id, videos);
                  }
                  if (pdfs != null && pdfs.isNotEmpty) {
                    await ref
                        .read(notesProvider.notifier)
                        .attachPdfsFromPaths(newNote.id, pdfs);
                  }
                  return newNote;
                },
            onMove: (id, delta) =>
                ref.read(notesProvider.notifier).move(id, delta),
            onView: _view,
            onTogglePin: (id) => ref.read(notesProvider.notifier).togglePin(id),
          ),

          // Loading overlay — shown until the first state update from _init().
          if (_loading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }

  void _openSearchSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SearchSheet(
        onSelect: (noteFromSearch) {
          Navigator.pop(ctx);
          final current = ref
              .read(notesProvider)
              .firstWhere(
                (n) => n.id == noteFromSearch.id,
                orElse: () => noteFromSearch,
              );
          _canvas.zoomToRect(
            context,
            Rect.fromLTWH(
              current.pos.dx,
              current.pos.dy,
              current.size.width,
              current.size.height,
            ),
          );
        },
      ),
    );
  }

  Future<void> _view(Note note) async {
    final outcome = await showViewNoteDialog(
      context: context,
      note: note,
      onAddImages: (id) => ref.read(notesProvider.notifier).attachImages(id),
      onRemoveImage: (id, path) =>
          ref.read(notesProvider.notifier).removeImage(id, path),
      onAddVideos: (id) => ref.read(notesProvider.notifier).attachVideos(id),
      onRemoveVideo: (id, vPath) =>
          ref.read(notesProvider.notifier).removeVideo(id, vPath),
      onAddPdf: (id) => ref.read(notesProvider.notifier).attachPdfs(id),
      onRemovePdf: (id, path) =>
          ref.read(notesProvider.notifier).removePdf(id, path),
    );

    if (outcome == null) return;

    if (outcome.deleted) {
      ref.read(notesProvider.notifier).remove(note.id);
      return;
    }

    // Build the updated note and track whether anything actually changed.
    var updated = note;
    var dirty = false;

    if (outcome.newTitle != null && outcome.newTitle != note.title) {
      updated = updated.copyWith(title: outcome.newTitle);
      dirty = true;
    }
    if (outcome.newText != null && outcome.newText != note.text) {
      updated = updated.copyWith(text: outcome.newText);
      dirty = true;
    }
    if (outcome.newColorValue != null &&
        outcome.newColorValue != note.colorValue) {
      updated = updated.copyWith(colorValue: outcome.newColorValue);
      dirty = true;
    }

    if (dirty) {
      ref.read(notesProvider.notifier).update(updated);
    }
  }

  Future<void> _export() async {
    final repo = ref.read(repositoryProvider);
    final file = await repo.exportToJsonFile();
    await SharePlus.instance.share(
      ShareParams(text: 'Anteckningar exporterade', files: [XFile(file.path)]),
    );
  }

  Future<void> _import() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;

    final count = await ref
        .read(repositoryProvider)
        .importFromJsonFile(File(path), replaceExisting: false);

    await ref.read(notesProvider.notifier).reload();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importerade $count anteckningar')),
      );
    }
  }
}
