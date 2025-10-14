import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/features/canvas/widgets/canvas_viewport.dart';
import 'package:gk_notes/features/canvas/widgets/edit_note_dialog.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/note.dart';
import '../../data/models/repositories/hive_note_repository.dart';
import '../search/search_bar.dart';
import 'canvas_controller.dart';
import 'providers.dart';

class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({super.key});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  final CanvasController canvas = CanvasController();
  final Size canvasSize = const Size(20000, 20000);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCamera(scale: 0.45); // tweak this to start more/less zoomed out
    });
  }

  void _centerCamera({double scale = 0.3}) {
    final viewport = MediaQuery.of(context).size;

    // focus point: canvas center
    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    // we want: x' = s*x + tx = viewportWidth/2  (same for y)
    final tx = viewport.width / 2 - scale * cx;
    final ty = viewport.height / 2 - scale * cy;

    // Apply SCALE first, then TRANSLATE → gives x' = s*x + tx
    canvas.transformController.value = Matrix4.identity()
      ..scale(scale)
      ..translate(tx, ty);
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GK Anteckningar'),
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
                  title: Text('Export JSON'),
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Import JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearchSheet,
        child: const Icon(Icons.search),
      ),
      body: CanvasViewport(
        controller: canvas,
        canvasSize: canvasSize,
        notes: notes,
        onAddAt: (scenePoint) =>
            ref.read(notesProvider.notifier).addAt(scenePoint),
        onMove: (id, delta) => ref.read(notesProvider.notifier).move(id, delta),
        onEdit: _edit,
      ),
    );
  }

  Future<void> _openSearchSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SearchSheet(
        onSelect: (note) {
          Navigator.pop(ctx);
          final rect = Rect.fromLTWH(
            note.pos.dx,
            note.pos.dy,
            note.size.width,
            note.size.height,
          );
          canvas.zoomToRect(context, rect);
        },
      ),
    );
  }

  Future<void> _edit(Note note) async {
    final outcome = await showEditNoteDialog(context: context, note: note);
    if (outcome == null) return; // cancelled
    if (outcome.deleted) {
      ref.read(notesProvider.notifier).remove(note.id);
      return;
    }
    if (outcome.newText != null) {
      ref
          .read(notesProvider.notifier)
          .update(note.copyWith(text: outcome.newText));
    }
  }

  Future<void> _export() async {
    final repo = ref.read(repositoryProvider) as HiveNoteRepository;
    final file = await repo.exportToJsonFile();
    await Share.shareXFiles([XFile(file.path)], text: 'Canvas Notes export');
  }

  Future<void> _import() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (res == null || res.files.isEmpty) return;
    final path = res.files.single.path;
    if (path == null) return;
    final repo = ref.read(repositoryProvider) as HiveNoteRepository;
    final count = await repo.importFromJsonFile(
      File(path),
      replaceExisting: false,
    );
    final loaded = await repo.load();
    ref.read(notesProvider.notifier).state = loaded;
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported $count notes')));
    }
  }
}
