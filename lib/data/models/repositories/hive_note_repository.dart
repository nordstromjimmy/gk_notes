import 'dart:convert';
import 'dart:io';
import 'package:gk_notes/data/models/note.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class HiveNoteRepository {
  static const _boxName = 'notes_box';
  Box<Map>? _box;

  Future<Box<Map>> _db() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  Future<List<Note>> load() async {
    final box = await _db();
    final notes = <Note>[];
    for (final raw in box.values) {
      final note = Note.tryFromHiveMap(Map<String, dynamic>.from(raw));
      if (note != null) notes.add(note);
      // Corrupted entries are silently skipped rather than crashing the app.
    }
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  /// Persists a single note. Fast path for individual updates/moves.
  Future<void> upsert(Note note) async {
    final box = await _db();
    await box.put(note.id, note.toHiveMap());
  }

  /// Removes a single note by id. Fast path for deletions.
  Future<void> removeById(String id) async {
    final box = await _db();
    await box.delete(id);
  }

  /// Syncs the box to exactly match [notes].
  /// Writes only changed entries and deletes removed ones —
  /// never clears the whole box first, so a crash mid-write
  /// cannot produce an empty database.
  Future<void> saveAll(List<Note> notes) async {
    final box = await _db();

    // Build the desired state.
    final desired = {for (final n in notes) n.id: n.toHiveMap()};

    // Write new / changed entries.
    await box.putAll(desired);

    // Delete entries that are no longer in the list.
    final toDelete = box.keys.where((k) => !desired.containsKey(k)).toList();
    if (toDelete.isNotEmpty) await box.deleteAll(toDelete);
  }

  // ---- export / import (unchanged — uses the stable public JSON format) ----

  Future<File> exportToJsonFile({
    String filename = 'grid_notes_export.json',
  }) async {
    final box = await _db();
    // Re-parse through Note so the export always uses toExportJson(),
    // even if the internal Hive format has diverged.
    final notes = <Map<String, dynamic>>[];
    for (final raw in box.values) {
      final note = Note.tryFromHiveMap(Map<String, dynamic>.from(raw));
      if (note != null) notes.add(note.toExportJson());
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(notes));
    return file;
  }

  Future<int> importFromJsonFile(
    File file, {
    bool replaceExisting = false,
  }) async {
    final text = await file.readAsString();
    final raw = jsonDecode(text) as List;
    final items = raw
        .map((e) => Note.fromImportJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final box = await _db();
    if (replaceExisting) await box.clear();

    for (final n in items) {
      final existing = box.get(n.id);
      if (existing == null) {
        await box.put(n.id, n.toHiveMap());
      } else {
        final cur = Note.tryFromHiveMap(Map<String, dynamic>.from(existing));
        final newer = (cur == null || n.updatedAt.isAfter(cur.updatedAt))
            ? n
            : cur;
        await box.put(newer.id, newer.toHiveMap());
      }
    }
    return items.length;
  }
}
