import '../../data/models/note.dart';

class SearchResult {
  final Note note;
  final double score;
  SearchResult(this.note, this.score);
}

/// Scores a note by matching the query against both `title` and `text`.
/// - Title hits are boosted so they rank higher.
/// - Earlier matches score higher than later ones (position-based).
/// - Multiple tokens are supported; all-token presence gets a small bonus.
/// - Recent notes get a gentle recency boost.
double scoreNote(Note n, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;

  final title = (n.title).toLowerCase();
  final body = (n.text).toLowerCase();

  // Tokenize on non-letter/digit boundaries (handles Swedish chars too).
  final tokens = _tokenize(q);
  if (tokens.isEmpty) return 0;

  const titleBoost = 2.5;

  double score = 0;

  // Position-weighted scoring per token, for both title and body.
  for (final t in tokens) {
    final ti = title.indexOf(t);
    if (ti >= 0) {
      score += titleBoost * (1.0 / (ti + 1));
    }
    final bi = body.indexOf(t);
    if (bi >= 0) {
      score += (1.0 / (bi + 1));
    }
  }

  // Small bonus if all tokens appear somewhere in title or body.
  final allPresent = tokens.every((t) => title.contains(t) || body.contains(t));
  if (allPresent) score += 0.5;

  // Gentle recency boost (newer notes rank a bit higher).
  final hours = DateTime.now().difference(n.updatedAt).inHours + 1;
  final recency = 1.0 / hours;
  score += recency;

  // If nothing matched, return 0.
  return score.isFinite && score > 0 ? score : 0;
}

List<String> _tokenize(String s) {
  return s
      .toLowerCase()
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}
