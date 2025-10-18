import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:gk_notes/data/models/repositories/hive_note_repository.dart';
import 'package:gk_notes/data/models/repositories/note_repository.dart';
import 'package:gk_notes/domain/search/scoring.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/note.dart';
import '../../domain/search/search_service.dart';

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

final repositoryProvider = Provider<NoteRepository>(
  (ref) => HiveNoteRepository(),
);

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends Notifier<List<Note>> {
  late final NoteRepository _repo;
  late final SearchService _search;
  final _uuid = const Uuid();

  void togglePin(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(pinned: !n.pinned, updatedAt: DateTime.now())
        else
          n,
    ];
    _search.index(state);
    saveDebounced();
  }

  @override
  List<Note> build() {
    _repo = ref.read(repositoryProvider);
    _search = ref.read(searchServiceProvider);
    _init();
    return [];
  }

  Future<void> _init() async {
    final loaded = await _repo.load();
    state = loaded;
    _search.index(state);
  }

  Future<Note> addAt(
    Offset canvasPoint, {
    required String title,
    required String text,
    int? colorValue,
  }) async {
    final n = Note.create(
      id: _uuid.v4(),
      title: title.isEmpty ? '' : title,
      text: text,
      pos: canvasPoint,
      size: const Size(200, 140),
      colorValue: colorValue ?? const Color(0xFF38464F).value,
    );
    state = [...state, n];
    _search.index(state);
    await save();
    return n;
  }

  void update(Note note) {
    state = [
      for (final n in state)
        if (n.id == note.id) note.copyWith(updatedAt: DateTime.now()) else n,
    ];
    _search.index(state);
    save();
  }

  void move(String id, Offset delta) {
    state = [
      for (final n in state)
        if (n.id == id)
          (n.pinned)
              ? n
              : n.copyWith(pos: n.pos + delta, updatedAt: DateTime.now())
        else
          n,
    ];
    saveDebounced();
  }

  Future<void> reload() async {
    final loaded = await _repo.load();
    state = loaded;
    _search.index(state);
  }

  void resize(String id, Size newSize) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(size: newSize, updatedAt: DateTime.now())
        else
          n,
    ];
    saveDebounced();
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
    _search.index(state);
    save();
  }

  Future<List<String>> attachImagesFromBytes(
    String id,
    List<ImageToAttach> imgs,
  ) async {
    if (imgs.isEmpty) {
      return state.firstWhere((n) => n.id == id).imagePaths;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final noteDir = Directory('${appDir.path}/notes/$id');
    if (!await noteDir.exists()) await noteDir.create(recursive: true);

    final added = <String>[];
    for (final img in imgs) {
      final name = '${DateTime.now().microsecondsSinceEpoch}${img.ext}';
      final dest = File('${noteDir.path}/$name');
      await dest.writeAsBytes(img.bytes, flush: true);
      added.add(dest.path);
    }

    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            imagePaths: [...n.imagePaths, ...added],
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
    _search.index(state);
    saveDebounced();

    return state.firstWhere((n) => n.id == id).imagePaths;
  }

  // Pick from gallery and attach to an existing note.
  Future<void> attachImages(String id) async {
    final addedPaths = <String>[];

    // Ensure note folder
    final appDir = await getApplicationDocumentsDirectory();
    final noteDir = Directory('${appDir.path}/notes/$id');
    if (!await noteDir.exists()) await noteDir.create(recursive: true);

    // Try image_picker (best UX on Android/iOS)
    try {
      final picker = ImagePicker();
      final picks = await picker.pickMultiImage(imageQuality: 85);
      if (picks.isNotEmpty) {
        for (final x in picks) {
          final ext = p.extension(x.name).isNotEmpty
              ? p.extension(x.name)
              : '.jpg';
          final dest = File(
            '${noteDir.path}/${DateTime.now().microsecondsSinceEpoch}$ext',
          );
          await File(x.path).copy(dest.path);
          addedPaths.add(dest.path);
        }
      }
    } on PlatformException {
      // fall through to file_picker below
    } catch (_) {
      // fall through to file_picker below
    }

    // Fallback: file_picker (works even when image_picker channel fails)
    if (addedPaths.isEmpty) {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        for (final f in res.files) {
          final bytes =
              f.bytes ??
              (f.path != null ? await File(f.path!).readAsBytes() : null);
          if (bytes == null) continue;
          final ext = p.extension(f.name).isNotEmpty
              ? p.extension(f.name)
              : '.jpg';
          final dest = File(
            '${noteDir.path}/${DateTime.now().microsecondsSinceEpoch}$ext',
          );
          await dest.writeAsBytes(bytes, flush: true);
          addedPaths.add(dest.path);
        }
      }
    }

    if (addedPaths.isEmpty) return;

    // Update state
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            imagePaths: [...n.imagePaths, ...addedPaths],
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
    _search.index(state);
    saveDebounced();
  }

  Future<void> removeImage(String id, String path) async {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            imagePaths: n.imagePaths.where((p) => p != path).toList(),
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    _search.index(state);
    saveDebounced();
  }

  // ---- persistence helpers ----
  Future<void> save() async => _repo.saveAll(state);

  // very light debounce: avoids spamming disk while dragging
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> saveDebounced({
    Duration minGap = const Duration(milliseconds: 250),
  }) async {
    final now = DateTime.now();
    if (now.difference(_lastSave) >= minGap) {
      _lastSave = now;
      await _repo.saveAll(state);
    }
  }

  // ---- search ----
  List<SearchResult> search(String query) =>
      ref.read(searchServiceProvider).search(query);
}
