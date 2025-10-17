import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gk_notes/data/models/repositories/hive_note_repository.dart';
import 'package:gk_notes/data/models/repositories/note_repository.dart';
import 'package:gk_notes/domain/search/scoring.dart';
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

  Future<void> addAt(
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
    await save(); // <- make sure this is awaited
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
          n.copyWith(pos: n.pos + delta, updatedAt: DateTime.now())
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
