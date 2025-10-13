import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:gk_notes/data/models/repositories/hive_note_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show MatrixUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note.dart';
import 'providers.dart';
import 'canvas_controller.dart';
import 'widgets/grid_painter.dart';
import 'widgets/note_card.dart';
import '../search/search_bar.dart'; // contains _SearchSheet

class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({super.key});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  final CanvasController canvas = CanvasController();
  final Size canvasSize = const Size(8000, 8000);
  // query is managed inside the bottom sheet now
  String query = '';

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canvas Notes'),
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

      // Bottom search affordance
      floatingActionButton: FloatingActionButton(
        onPressed: _openSearchSheet,
        child: const Icon(Icons.search),
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (d) {
          // Map from screen-local coords to canvas coords using the current transform
          final inv = canvas.transformController.value.clone()..invert();
          final scenePoint = MatrixUtils.transformPoint(inv, d.localPosition);
          ref.read(notesProvider.notifier).addAt(scenePoint);
        },
        child: InteractiveViewer(
          transformationController: canvas.transformController,
          minScale: 0.25,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(4000),
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: GridPainter())),
                for (final n in notes)
                  Positioned(
                    left: n.pos.dx,
                    top: n.pos.dy,
                    child: _DraggableNote(
                      note: n,
                      onEdit: () => _edit(n),
                      onDrag: (delta) =>
                          ref.read(notesProvider.notifier).move(n.id, delta),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSearchSheet() async {
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
    final ctl = TextEditingController(text: note.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit note'),
        content: TextField(
          minLines: 3,
          maxLines: 10,
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Type your note…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      ref.read(notesProvider.notifier).update(note.copyWith(text: result));
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

class _DraggableNote extends StatefulWidget {
  const _DraggableNote({
    required this.note,
    required this.onEdit,
    required this.onDrag,
  });
  final Note note;
  final VoidCallback onEdit;
  final ValueChanged<Offset> onDrag;

  @override
  State<_DraggableNote> createState() => _DraggableNoteState();
}

class _DraggableNoteState extends State<_DraggableNote> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onEdit,
      onPanUpdate: (d) {
        // Drag delta is in screen space; convert to canvas space by dividing by current scale
        final scale =
            (context
                .findAncestorStateOfType<_CanvasPageState>()
                ?.canvas
                .transformController
                .value
                .getMaxScaleOnAxis()) ??
            1.0;
        widget.onDrag(d.delta / scale);
      },
      child: NoteCard(note: widget.note, highlighted: false),
    );
  }
}
