import '../../data/models/note.dart';

class SearchResult {
  final Note note;
  final double score;
  SearchResult(this.note, this.score);
}

double scoreNote(Note n, String query) {
  final q = query.toLowerCase();
  final t = n.text.toLowerCase();
  if (q.isEmpty) return 0;
  final idx = t.indexOf(q);
  if (idx < 0) return 0;
  // Simple score: earlier match and recency boost
  final recency = 1.0 / (DateTime.now().difference(n.updatedAt).inHours + 1);
  return 1.0 / (idx + 1) + recency;
}
