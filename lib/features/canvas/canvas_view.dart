import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:gk_notes/data/models/repositories/hive_note_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note.dart';
import 'providers.dart';
import 'canvas_controller.dart';
import 'widgets/grid_painter.dart';
import 'widgets/note_card.dart';
import '../search/search_bar.dart';

class CanvasPage extends ConsumerStatefulWidget {
  const CanvasPage({super.key});

  @override
  ConsumerState<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends ConsumerState<CanvasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewport = MediaQuery.of(context).size;
      final dx = -(canvasSize.width / 2 - viewport.width / 2);
      final dy = -(canvasSize.height / 2 - viewport.height / 2);
      canvas.transformController.value = Matrix4.identity()..translate(dx, dy);
    });
  }

  final CanvasController canvas = CanvasController();
  final Size canvasSize = const Size(20000, 20000);
  // query is managed inside the bottom sheet now
  String query = '';

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
          constrained: false,
          clipBehavior: Clip.none,
          alignment: Alignment.topLeft,
          minScale: 0.25,
          maxScale: 12,
          boundaryMargin: const EdgeInsets.all(50000),
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: canvas.transformController,
                    builder: (_, __) {
                      final scale = canvas.transformController.value
                          .getMaxScaleOnAxis();
                      return CustomPaint(
                        painter: GridPainter(
                          spacing: 64,
                          majorEvery: 14,
                          scale: scale,
                        ),
                      );
                    },
                  ),
                ),
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

    // Show edit dialog
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        // Title with trash icon on the right
        title: Row(
          children: [
            const Text('Redigera'),
            const Spacer(),
            IconButton(
              tooltip: 'Radera',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                // Confirm delete
                final sure = await showDialog<bool>(
                  context: ctx,
                  builder: (c2) => AlertDialog(
                    title: const Text('Radera?'),
                    content: const Text('Vill du radera denna anteckning?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c2, false),
                        child: const Text('Avbryt'),
                      ),
                      FilledButton.tonal(
                        onPressed: () => Navigator.pop(c2, true),
                        child: const Text('Radera'),
                      ),
                    ],
                  ),
                );
                if (sure == true) {
                  // Close the edit dialog
                  Navigator.pop(ctx);
                  // Delete the note
                  ref.read(notesProvider.notifier).remove(note.id);
                }
              },
            ),
          ],
        ),

        content: TextField(
          minLines: 3,
          maxLines: 10,
          controller: ctl,
          autofocus: false,
          decoration: const InputDecoration(hintText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Spara'),
          ),
        ],
      ),
    );

    // Save edits (only if not deleted)
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
