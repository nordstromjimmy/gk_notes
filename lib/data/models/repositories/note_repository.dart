import 'package:gk_notes/data/models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> load();
  Future<void> saveAll(List<Note> notes);
  Future<void> upsert(Note note);
  Future<void> removeById(String id);
}
