import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, this.onTogglePin});

  final Note note;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final hasTitle = note.title.isNotEmpty;
    final hasText = note.text.isNotEmpty;
    final hasMedia =
        note.imagePaths.isNotEmpty ||
        note.videoPaths.isNotEmpty ||
        note.pdfPaths.isNotEmpty;

    return RepaintBoundary(
      child: SizedBox(
        width: note.size.width,
        height: note.size.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: note.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 2, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          hasTitle ? note.title : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          onPressed: onTogglePin,
                          tooltip: note.pinned ? 'Unpin' : 'Pin',
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            note.pinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 13,
                            color: note.pinned
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---- Body ----
                if (hasText)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        10,
                        hasTitle ? 3 : 8,
                        10,
                        hasMedia ? 4 : 7,
                      ),
                      child: Text(
                        note.text,
                        softWrap: true,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  )
                else
                  const Spacer(),

                // ---- Media footer ----
                if (hasMedia)
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 5),
                    color: Colors.black.withValues(alpha: 0.18),
                    child: Row(
                      children: [
                        if (note.imagePaths.isNotEmpty) ...[
                          Icon(
                            Icons.image_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${note.imagePaths.length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (note.videoPaths.isNotEmpty) ...[
                          Icon(
                            Icons.videocam_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${note.videoPaths.length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (note.pdfPaths.isNotEmpty) ...[
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${note.pdfPaths.length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
