import 'package:flutter/material.dart';
import '../../../data/models/note.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, this.onTogglePin});

  final Note note;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    const hPad = 6.0;
    const vPad = 6.0;
    const gapT = 4.0;
    const iconSize = 16.0;

    final hasTitle = note.title.isNotEmpty;
    final hasText = note.text.isNotEmpty;

    return RepaintBoundary(
      child: SizedBox(
        width: note.size.width,
        height: note
            .size
            .height, // constrained — body text can no longer overflow into other notes
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
            decoration: BoxDecoration(
              color: note.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white70, height: 1.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row: title + media badges + pin button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasTitle ? note.title : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      // Individual media-type icons so the user knows what's attached.
                      if (note.imagePaths.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.image_outlined,
                            size: iconSize,
                            color: Colors.white70,
                          ),
                        ),
                      if (note.videoPaths.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.videocam_outlined,
                            size: iconSize,
                            color: Colors.white70,
                          ),
                        ),
                      if (note.pdfPaths.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.picture_as_pdf_outlined,
                            size: iconSize,
                            color: Colors.white70,
                          ),
                        ),

                      // Pin button — splashRadius replaced with styleFrom.
                      IconButton(
                        onPressed: onTogglePin,
                        tooltip: note.pinned ? 'Unpin' : 'Pin',
                        icon: Icon(
                          note.pinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: iconSize,
                        ),
                        color: Colors.white70,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  if (hasTitle && hasText) const SizedBox(height: gapT),

                  // Body text — clipped by the parent SizedBox, ellipsis on last visible line.
                  if (hasText)
                    Expanded(
                      child: Text(
                        note.text,
                        softWrap: true,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
