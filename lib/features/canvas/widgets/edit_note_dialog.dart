import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gk_notes/theme/note_colors.dart';
import 'package:path/path.dart' as p show basename;
import '../../../data/models/note.dart';
import 'create_note_dialog.dart'
    show
        _ColorSwatch,
        _SectionLabel,
        _MediaSection,
        _ChipList,
        _RemoveBadge,
        _fieldDecoration;
import 'note_dialog_shared.dart';

// ---- Public types (unchanged) ----

class NoteEditOutcome {
  final String? newTitle;
  final String? newText;
  final int? newColorValue;
  final bool deleted;
  const NoteEditOutcome({
    this.newTitle,
    this.newText,
    this.newColorValue,
    this.deleted = false,
  });
}

typedef AddImagesFn = Future<List<String>> Function(String noteId);
typedef RemoveImageFn =
    Future<List<String>> Function(String noteId, String path);
typedef AddPdfFn = Future<List<String>> Function(String noteId);
typedef RemovePdfFn =
    Future<List<String>> Function(String noteId, String pdfPath);

class VideoUpdate {
  final List<String> videoPaths;
  final List<String> thumbPaths;
  const VideoUpdate(this.videoPaths, this.thumbPaths);
}

typedef AddVideosFn = Future<VideoUpdate> Function(String noteId);
typedef RemoveVideoFn =
    Future<VideoUpdate> Function(String noteId, String videoPath);

// ---- Entry point ----

Future<NoteEditOutcome?> showEditNoteDialog({
  required BuildContext context,
  required Note note,
  AddImagesFn? onAddImages,
  RemoveImageFn? onRemoveImage,
  AddVideosFn? onAddVideos,
  RemoveVideoFn? onRemoveVideo,
  AddPdfFn? onAddPdf,
  RemovePdfFn? onRemovePdf,
}) async {
  final result = await showDialog<_InternalResult>(
    context: context,
    builder: (_) => _EditNoteDialog(
      note: note,
      onAddImages: onAddImages,
      onRemoveImage: onRemoveImage,
      onAddVideos: onAddVideos,
      onRemoveVideo: onRemoveVideo,
      onAddPdf: onAddPdf,
      onRemovePdf: onRemovePdf,
    ),
  );

  if (result == null) return null;
  if (result.deleted) return const NoteEditOutcome(deleted: true);

  return NoteEditOutcome(
    newTitle: result.title != note.title ? result.title : null,
    newText: result.text != note.text ? result.text : null,
    newColorValue: result.colorValue != note.colorValue
        ? result.colorValue
        : null,
  );
}

// ---- Dialog widget ----

class _EditNoteDialog extends StatefulWidget {
  const _EditNoteDialog({
    required this.note,
    this.onAddImages,
    this.onRemoveImage,
    this.onAddVideos,
    this.onRemoveVideo,
    this.onAddPdf,
    this.onRemovePdf,
  });

  final Note note;
  final AddImagesFn? onAddImages;
  final RemoveImageFn? onRemoveImage;
  final AddVideosFn? onAddVideos;
  final RemoveVideoFn? onRemoveVideo;
  final AddPdfFn? onAddPdf;
  final RemovePdfFn? onRemovePdf;

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  late final TextEditingController _titleCtl;
  late final TextEditingController _bodyCtl;
  late int _selectedColor;
  late List<String> _images;
  late List<String> _videos;
  late List<String> _videoThumbs;
  late List<String> _pdfs;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.note.title);
    _bodyCtl = TextEditingController(text: widget.note.text);
    _selectedColor = noteColorIndexOf(widget.note.colorValue);
    _images = List.from(widget.note.imagePaths);
    _videos = List.from(widget.note.videoPaths);
    _videoThumbs = List.from(widget.note.videoThumbPaths);
    _pdfs = List.from(widget.note.pdfPaths);
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _bodyCtl.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(
    context,
    _InternalResult.save(
      _titleCtl.text.trim(),
      _bodyCtl.text,
      kNoteColors[_selectedColor].value,
    ),
  );

  Future<void> _confirmDelete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Do you want to delete this note?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.38),
                ),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (sure == true && mounted) {
      Navigator.pop(context, const _InternalResult.delete());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = (MediaQuery.of(context).size.width * 0.92).clamp(
      320.0,
      680.0,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF263238),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      title: Row(
        children: [
          const Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Radera',
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Title ----
              TextField(
                controller: _titleCtl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: fieldDecoration('Title', hint: 'Enter a title..'),
              ),
              const SizedBox(height: 10),

              // ---- Body ----
              TextField(
                controller: _bodyCtl,
                minLines: 3,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: fieldDecoration(
                  'Note',
                  hint: 'Enter your note..',
                  alignLabel: true,
                ),
              ),
              const SizedBox(height: 16),

              // ---- Color picker ----
              SectionLabel('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < kNoteColors.length; i++)
                    NoteColorSwatch(
                      color: kNoteColors[i],
                      selected: _selectedColor == i,
                      onTap: () => setState(() => _selectedColor = i),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Images ----
              MediaSection(
                label: 'Picture',
                icon: Icons.add_photo_alternate_outlined,
                onAdd: widget.onAddImages == null
                    ? () {}
                    : () async {
                        final updated = await widget.onAddImages!(
                          widget.note.id,
                        );
                        setState(() => _images = updated);
                      },
                child: _images.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final path = _images[i];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _brokenImage(),
                                  ),
                                ),
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: RemoveBadge(
                                    onTap: widget.onRemoveImage == null
                                        ? () {}
                                        : () async {
                                            final updated =
                                                await widget.onRemoveImage!(
                                                  widget.note.id,
                                                  path,
                                                );
                                            setState(() => _images = updated);
                                          },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // ---- Videos ----
              MediaSection(
                label: 'Video',
                icon: Icons.video_collection_outlined,
                onAdd: widget.onAddVideos == null
                    ? () {}
                    : () async {
                        final upd = await widget.onAddVideos!(widget.note.id);
                        setState(() {
                          _videos = upd.videoPaths;
                          _videoThumbs = upd.thumbPaths;
                        });
                      },
                child: _videos.isEmpty
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _videos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final tPath = i < _videoThumbs.length
                                ? _videoThumbs[i]
                                : null;
                            return Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: (tPath != null && tPath.isNotEmpty)
                                      ? Image.file(
                                          File(tPath),
                                          width: 150,
                                          height: 88,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _thumbFallback(),
                                        )
                                      : _thumbFallback(),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: RemoveBadge(
                                    onTap: widget.onRemoveVideo == null
                                        ? () {}
                                        : () async {
                                            final upd =
                                                await widget.onRemoveVideo!(
                                                  widget.note.id,
                                                  _videos[i],
                                                );
                                            setState(() {
                                              _videos = upd.videoPaths;
                                              _videoThumbs = upd.thumbPaths;
                                            });
                                          },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // ---- PDFs ----
              MediaSection(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                onAdd: widget.onAddPdf == null
                    ? () {}
                    : () async {
                        final updated = await widget.onAddPdf!(widget.note.id);
                        setState(() => _pdfs = updated);
                      },
                child: _pdfs.isEmpty
                    ? const SizedBox.shrink()
                    : ChipList(
                        items: _pdfs,
                        onRemove: widget.onRemovePdf == null
                            ? (_) {}
                            : (i) async {
                                final updated = await widget.onRemovePdf!(
                                  widget.note.id,
                                  _pdfs[i],
                                );
                                setState(() => _pdfs = updated);
                              },
                      ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.38),
              ),
              child: const Text('Cancel'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF546E7A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Private helpers ----

Widget _brokenImage() => Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    color: const Color(0xFF1A2530),
    borderRadius: BorderRadius.circular(8),
  ),
  alignment: Alignment.center,
  child: Icon(
    Icons.broken_image_outlined,
    color: Colors.white.withValues(alpha: 0.3),
  ),
);

Widget _thumbFallback() => Container(
  width: 150,
  height: 88,
  decoration: BoxDecoration(
    color: const Color(0xFF1A2530),
    borderRadius: BorderRadius.circular(8),
  ),
  alignment: Alignment.center,
  child: Icon(
    Icons.videocam_outlined,
    color: Colors.white.withValues(alpha: 0.3),
  ),
);

class _InternalResult {
  final String? title;
  final String? text;
  final int? colorValue;
  final bool deleted;
  const _InternalResult._(this.title, this.text, this.colorValue, this.deleted);
  const _InternalResult.delete() : this._(null, null, null, true);
  const _InternalResult.save(String t, String b, int c)
    : this._(t, b, c, false);
}
