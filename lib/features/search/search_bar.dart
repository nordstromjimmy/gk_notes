import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/note.dart';
import '../canvas/providers.dart';

class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key, required this.onSelect});
  final ValueChanged<Note> onSelect;

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  final TextEditingController _ctl = TextEditingController();
  List<Note> _results = const [];

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _run(String q) {
    final r = ref.read(notesProvider.notifier).search(q);
    setState(() {
      _results = r.map((e) => e.note).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _ctl,
                autofocus: false,
                onChanged: _run,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Sök..',
                  isDense: true,
                ),
              ),
            ),
            Flexible(
              child: _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Inga resultat'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final n = _results[i];

                        // Prefer the explicit title; fall back to first line of text.
                        final lines = n.text.split('\n');
                        final firstLine = lines.isNotEmpty ? lines.first : '';
                        final rest = (lines.length > 1)
                            ? lines.skip(1).join('\n')
                            : '';

                        final displayTitle = n.title.isNotEmpty
                            ? n.title
                            : firstLine;
                        // If we’re using the first line as title, show the remaining text as subtitle.
                        final displaySubtitle = n.title.isNotEmpty
                            ? n.text
                            : rest;

                        return ListTile(
                          title: Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: displaySubtitle.trim().isEmpty
                              ? null
                              : Text(
                                  displaySubtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => widget.onSelect(n),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
