import 'package:collection/collection.dart';
import '../../data/models/note.dart';
import 'scoring.dart';

class SearchService {
  List<Note> _notes = [];

  void index(List<Note> notes) {
    _notes = notes;
  }

  List<SearchResult> search(String query, {int limit = 20}) {
    if (query.trim().isEmpty) return [];
    final scored = _notes
        .map((n) => SearchResult(n, scoreNote(n, query)))
        .where((r) => r.score > 0)
        .sortedBy<num>((r) => -r.score)
        .toList();
    if (scored.length <= limit) return scored;
    return scored.take(limit).toList();
  }
}
