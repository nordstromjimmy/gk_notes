import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:gk_notes/data/models/repositories/hive_note_repository.dart';
import 'package:gk_notes/domain/search/scoring.dart';
import '../../data/models/note.dart';
import '../../domain/search/search_service.dart';
import '../media_service.dart';
import 'widgets/edit_note_dialog.dart';

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

final repositoryProvider = Provider<HiveNoteRepository>(
  (ref) => HiveNoteRepository(),
);

final mediaServiceProvider = Provider<MediaService>((ref) => MediaService());

final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

class NotesNotifier extends Notifier<List<Note>> {
  late final HiveNoteRepository _repo;
  late final SearchService _search;
  late final MediaService _media;
  final _uuid = const Uuid();

  @override
  List<Note> build() {
    _repo = ref.read(repositoryProvider);
    _search = ref.read(searchServiceProvider);
    _media = ref.read(mediaServiceProvider);

    // Cancel the debounce timer when the notifier is disposed.
    ref.onDispose(() => _saveTimer?.cancel());

    _init();
    return [];
  }

  Future<void> _init() async {
    final loaded = await _repo.load();
    state = loaded;
    _search.index(state);
  }

  // ------------------------------------------------------------------ CRUD

  Future<Note> addAt(
    Offset canvasPoint, {
    required String title,
    required String text,
    int? colorValue,
  }) async {
    final n = Note.create(
      id: _uuid.v4(),
      title: title,
      text: text,
      pos: canvasPoint,
      size: kDefaultNoteSize, // was Size(200, 140)
      colorValue: colorValue ?? const Color(0xFF38464F).value,
    );
    state = [...state, n];
    _search.index(state);
    await _repo.upsert(n);
    return n;
  }

  Future<void> update(Note note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    state = [
      for (final n in state)
        if (n.id == note.id) updated else n,
    ];
    _search.index(state);
    await _repo.upsert(updated);
  }

  void move(String id, Offset delta) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.pinned
              ? n
              : n.copyWith(pos: n.pos + delta, updatedAt: DateTime.now())
        else
          n,
    ];
    // Search index not updated here — position doesn't affect search results.
    _saveDebounced();
  }

  void resize(String id, Size newSize) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(size: newSize, updatedAt: DateTime.now())
        else
          n,
    ];
    // Search index not updated here — size doesn't affect search results.
    _saveDebounced();
  }

  void togglePin(String id) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(pinned: !n.pinned, updatedAt: DateTime.now())
        else
          n,
    ];
    _search.index(state);
    _saveDebounced();
  }

  Future<void> remove(String id) async {
    state = state.where((n) => n.id != id).toList();
    _search.index(state);
    await _repo.removeById(id);
  }

  Future<void> reload() async {
    final loaded = await _repo.load();
    state = loaded;
    _search.index(state);
  }

  // ------------------------------------------------------------------ images

  Future<List<String>> attachImagesFromBytes(
    String id,
    List<ImageToAttach> imgs,
  ) async {
    final added = await _media.saveImagesFromBytes(id, imgs);
    if (added.isEmpty) return _pathsFor(id).imagePaths;
    return _appendImages(id, added);
  }

  Future<List<String>> attachImages(String id) async {
    final added = await _media.pickAndSaveImages(id);
    if (added.isEmpty) return _pathsFor(id).imagePaths;
    return _appendImages(id, added);
  }

  Future<List<String>> removeImage(String id, String path) async {
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
    await _media.deleteFile(path);
    _search.index(state);
    _saveDebounced();
    return _pathsFor(id).imagePaths;
  }

  Future<List<String>> _appendImages(String id, List<String> added) {
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
    _saveDebounced();
    return Future.value(_pathsFor(id).imagePaths);
  }

  // ------------------------------------------------------------------ videos

  Future<VideoUpdate> attachVideos(String id) async {
    final result = await _media.pickAndSaveVideos(id);
    return _appendVideos(id, result.videoPaths, result.thumbPaths);
  }

  Future<VideoUpdate> attachVideosFromPaths(
    String id,
    List<String> srcPaths,
  ) async {
    if (srcPaths.isEmpty) return _videoUpdateFor(id);
    final result = await _media.saveVideosFromPaths(id, srcPaths);
    return _appendVideos(id, result.videoPaths, result.thumbPaths);
  }

  Future<VideoUpdate> removeVideo(String id, String videoPath) async {
    final note = _pathsFor(id);
    final idx = note.videoPaths.indexOf(videoPath);
    if (idx < 0) return _videoUpdateFor(id);

    final thumbPath = idx < note.videoThumbPaths.length
        ? note.videoThumbPaths[idx]
        : null;

    final newVideos = [...note.videoPaths]..removeAt(idx);
    final newThumbs = [...note.videoThumbPaths];
    if (idx < newThumbs.length) newThumbs.removeAt(idx);

    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            videoPaths: newVideos,
            videoThumbPaths: newThumbs,
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];

    await _media.deleteFile(videoPath);
    if (thumbPath != null && thumbPath.isNotEmpty) {
      await _media.deleteFile(thumbPath);
    }

    _search.index(state);
    _saveDebounced();
    return _videoUpdateFor(id);
  }

  VideoUpdate _appendVideos(
    String id,
    List<String> videos,
    List<String> thumbs,
  ) {
    if (videos.isEmpty) return _videoUpdateFor(id);
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            videoPaths: [...n.videoPaths, ...videos],
            videoThumbPaths: [...n.videoThumbPaths, ...thumbs],
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
    _search.index(state);
    _saveDebounced();
    return _videoUpdateFor(id);
  }

  // ------------------------------------------------------------------ PDFs

  Future<List<String>> attachPdfs(String id) async {
    final added = await _media.pickAndSavePdfs(id);
    if (added.isEmpty) return _pathsFor(id).pdfPaths;
    return _appendPdfs(id, added);
  }

  Future<List<String>> attachPdfsFromPaths(
    String id,
    List<String> srcPaths,
  ) async {
    if (srcPaths.isEmpty) return _pathsFor(id).pdfPaths;
    final added = await _media.savePdfsFromPaths(id, srcPaths);
    return _appendPdfs(id, added);
  }

  Future<List<String>> removePdf(String id, String pdfPath) async {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            pdfPaths: n.pdfPaths.where((p) => p != pdfPath).toList(),
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
    await _media.deleteFile(pdfPath);
    _search.index(state);
    _saveDebounced();
    return _pathsFor(id).pdfPaths;
  }

  Future<List<String>> _appendPdfs(String id, List<String> added) {
    state = [
      for (final n in state)
        if (n.id == id)
          n.copyWith(
            pdfPaths: [...n.pdfPaths, ...added],
            updatedAt: DateTime.now(),
          )
        else
          n,
    ];
    _search.index(state);
    _saveDebounced();
    return Future.value(_pathsFor(id).pdfPaths);
  }

  // ------------------------------------------------------------------ helpers

  /// Returns the current state snapshot for [id].
  /// Throws if the id is not in state (should never happen in practice).
  Note _pathsFor(String id) => state.firstWhere((n) => n.id == id);

  VideoUpdate _videoUpdateFor(String id) {
    final n = _pathsFor(id);
    return VideoUpdate(n.videoPaths, n.videoThumbPaths);
  }

  // ------------------------------------------------------------------ persistence

  Timer? _saveTimer;

  void _saveDebounced({Duration delay = const Duration(milliseconds: 500)}) {
    _saveTimer?.cancel();
    _saveTimer = Timer(delay, () => _repo.saveAll(state));
  }

  // ------------------------------------------------------------------ search

  List<SearchResult> search(String query) =>
      ref.read(searchServiceProvider).search(query);
}
