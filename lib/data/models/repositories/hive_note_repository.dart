import 'dart:convert';
import 'dart:io';
import 'package:gk_notes/data/models/note.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'note_repository.dart';

class HiveNoteRepository implements NoteRepository {
  static const _boxName = 'notes_box';
  Box<Map>? _box;

  Future<Box<Map>> _db() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  @override
  Future<List<Note>> load() async {
    final box = await _db();
    final items = box.values
        .map((m) => Note.fromImportJson(Map<String, dynamic>.from(m)))
        .toList();
    // Sort newest first by updatedAt
    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<void> saveAll(List<Note> notes) async {
    final box = await _db();
    await box.clear();
    await box.putAll({for (final n in notes) n.id: n.toExportJson()});
  }

  @override
  Future<void> upsert(Note note) async {
    final box = await _db();
    await box.put(note.id, note.toExportJson());
  }

  @override
  Future<void> removeById(String id) async {
    final box = await _db();
    await box.delete(id);
  }

  // ---- export/import helpers ----
  Future<File> exportToJsonFile({
    String filename = 'grid_notes_export.json',
  }) async {
    final box = await _db();
    final list = box.values.map((m) => Map<String, dynamic>.from(m)).toList();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(list));
    return file;
  }

  Future<int> importFromJsonFile(
    File file, {
    bool replaceExisting = false,
  }) async {
    final text = await file.readAsString();
    final raw = jsonDecode(text) as List;
    final items = raw
        .map((e) => Note.fromImportJson(Map<String, dynamic>.from(e)))
        .toList();

    final box = await _db();
    if (replaceExisting) {
      await box.clear();
    }
    // Merge by id (newer updatedAt wins)
    for (final n in items) {
      final existing = box.get(n.id);
      if (existing == null) {
        await box.put(n.id, n.toExportJson());
      } else {
        final cur = Note.fromImportJson(Map<String, dynamic>.from(existing));
        final newer = (n.updatedAt.isAfter(cur.updatedAt)) ? n : cur;
        await box.put(newer.id, newer.toExportJson());
      }
    }
    return items.length;
  }
}
