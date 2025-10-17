import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/features/canvas/widgets/canvas_viewport.dart';
import 'package:gk_notes/features/canvas/widgets/edit_note_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
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
    final cx = canvasSize.width / 2, cy = canvasSize.height / 2;

    final tx = viewport.width / 2 - scale * cx;
    final ty = viewport.height / 2 - scale * cy;

    canvas.transformController.value = Matrix4.compose(
      Vector3(tx, ty, 0), // translation
      Quaternion.identity(), // rotation
      Vector3(scale, scale, 1), // scale
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

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
      body: CanvasViewport(
        controller: canvas,
        canvasSize: canvasSize,
        notes: notes,
        onAddAt: (pos, {required title, required text, int? colorValue}) => ref
            .read(notesProvider.notifier)
            .addAt(pos, title: title, text: text, colorValue: colorValue),
        onMove: (id, delta) => ref.read(notesProvider.notifier).move(id, delta),
        onEdit: _edit,
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

          // Fetch the up-to-date note from the current state by id
          final current = ref
              .read(notesProvider)
              .firstWhere(
                (n) => n.id == noteFromSearch.id,
                orElse: () => noteFromSearch,
              );

          final rect = Rect.fromLTWH(
            current.pos.dx,
            current.pos.dy,
            current.size.width,
            current.size.height,
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
    var updated = note;
    if (outcome.newTitle != null) {
      updated = updated.copyWith(title: outcome.newTitle);
    }
    if (outcome.newText != null) {
      updated = updated.copyWith(text: outcome.newText);
    }
    if (outcome.newColorValue != null) {
      updated = updated.copyWith(colorValue: outcome.newColorValue);
    }

    // If anything changed, persist it
    if (!identical(updated, note)) {
      ref.read(notesProvider.notifier).update(updated);
    }
  }

  Future<void> _export() async {
    final repo = ref.read(repositoryProvider) as HiveNoteRepository;
    final file = await repo.exportToJsonFile();
    await SharePlus.instance.share(
      ShareParams(text: 'Notes export', files: [XFile(file.path)]),
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
    final repo = ref.read(repositoryProvider) as HiveNoteRepository;
    final count = await repo.importFromJsonFile(
      File(path),
      replaceExisting: false,
    );

    //await repo.load();
    await ref.read(notesProvider.notifier).reload();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importerade $count anteckningar')),
      );
    }
  }
}
