// view_note_dialog.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import '../../../data/models/note.dart';
import 'edit_note_dialog.dart';
import 'note_dialog_shared.dart';

enum _ViewAction { close, edit }

Future<NoteEditOutcome?> showViewNoteDialog({
  required BuildContext context,
  required Note note,
  AddImagesFn? onAddImages,
  RemoveImageFn? onRemoveImage,
  AddVideosFn? onAddVideos,
  RemoveVideoFn? onRemoveVideo,
  AddPdfFn? onAddPdf,
  RemovePdfFn? onRemovePdf,
}) async {
  final action = await showDialog<_ViewAction>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(320.0, 680.0);
      final maxContentH = MediaQuery.of(ctx).size.height - 220;

      return AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(
          // Thin top border in the note's own color — subtle identity cue.
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),

        title: Row(
          children: [
            // Note color dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: note.color,
                shape: BoxShape.circle,
              ),
            ),
            const Text(
              'Note',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Edit',
              icon: Icon(
                Icons.edit_outlined,
                color: Colors.white.withValues(alpha: 0.55),
                size: 20,
              ),
              onPressed: () => Navigator.pop(ctx, _ViewAction.edit),
            ),
          ],
        ),

        content: SizedBox(
          width: dialogWidth,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxContentH),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Note title ----
                  if (note.title.isNotEmpty) ...[
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ---- Note text ----
                  if (note.text.isNotEmpty)
                    Text(
                      note.text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),

                  // ---- Images ----
                  if (note.imagePaths.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionLabel('Picture'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: note.imagePaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final path = note.imagePaths[i];
                          return GestureDetector(
                            onTap: () => _showImageViewer(
                              ctx,
                              note.imagePaths,
                              initialIndex: i,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(path),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _brokenImageTile(88, 88),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ---- Videos ----
                  if (note.videoPaths.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionLabel('Video'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: note.videoPaths.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final thumb = i < note.videoThumbPaths.length
                              ? note.videoThumbPaths[i]
                              : null;
                          return GestureDetector(
                            onTap: () =>
                                _showVideoPlayer(ctx, note.videoPaths[i]),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: thumb != null && thumb.isNotEmpty
                                      ? Image.file(
                                          File(thumb),
                                          width: 150,
                                          height: 88,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _videoThumbFallback(),
                                        )
                                      : _videoThumbFallback(),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
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
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // ---- PDFs ----
                  if (note.pdfPaths.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const SectionLabel('PDF'),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        for (final pdf in note.pdfPaths)
                          _PdfTile(
                            path: pdf,
                            onTap: () async {
                              final res = await OpenFilex.open(pdf);
                              if (res.type != ResultType.done && ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Kunde inte öppna PDF (ingen app hittades?)',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),

        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
        actions: [
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, _ViewAction.close),
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
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (action != _ViewAction.edit) return null;

  return showEditNoteDialog(
    context: context,
    note: note,
    onAddImages: onAddImages,
    onRemoveImage: onRemoveImage,
    onAddVideos: onAddVideos,
    onRemoveVideo: onRemoveVideo,
    onAddPdf: onAddPdf,
    onRemovePdf: onRemovePdf,
  );
}

// ---- Image viewer ----

void _showImageViewer(
  BuildContext context,
  List<String> paths, {
  int initialIndex = 0,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (viewerCtx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: paths.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.file(
                File(paths[i]),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 48,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(viewerCtx).pop(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---- Video player ----

void _showVideoPlayer(BuildContext context, String path) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => _VideoPlayerDialog(path: path),
  );
}

class _VideoPlayerDialog extends StatefulWidget {
  const _VideoPlayerDialog({required this.path});
  final String path;

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _ctl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
        _ctl.play();
      });
    _ctl.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctl.removeListener(_onControllerUpdate);
    _ctl.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (!_ready) return;
    _ctl.value.isPlaying ? _ctl.pause() : _ctl.play();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _ready && _ctl.value.isPlaying;

    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _ready ? _ctl.value.aspectRatio : 16 / 9,
              child: _ready
                  ? VideoPlayer(_ctl)
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
            ),

            // Tap to toggle playback.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayback,
              ),
            ),

            // Play/pause overlay — fades out while playing.
            AnimatedOpacity(
              opacity: isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            // Progress bar.
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: VideoProgressIndicator(
                    _ctl,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Private helpers ----

Widget _brokenImageTile(double w, double h) => Container(
  width: w,
  height: h,
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

Widget _videoThumbFallback() => Container(
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

class _PdfTile extends StatelessWidget {
  const _PdfTile({required this.path, required this.onTap});
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2530),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p.basename(path),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
