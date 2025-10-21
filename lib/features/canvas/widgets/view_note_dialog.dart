// lib/features/canvas/widgets/view_note_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/note.dart';
import 'edit_note_dialog.dart';

enum _ViewAction { close, edit }

Future<NoteEditOutcome?> showViewNoteDialog({
  required BuildContext context,
  required Note note,
  AddImagesFn? onAddImages,
  RemoveImageFn? onRemoveImage,
  AddVideosFn? onAddVideos,
  RemoveVideoFn? onRemoveVideo,
}) async {
  final action = await showDialog<_ViewAction>(
    context: context,
    builder: (ctx) {
      final screenW = MediaQuery.of(ctx).size.width;
      final dialogWidth = (screenW * 0.92).clamp(360.0, 720.0);
      const bg = Color(0xFF38464F);
      const fgMuted = Colors.white70;

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        backgroundColor: bg,
        scrollable: true,
        title: Row(
          children: [
            const Text(
              'Anteckning',
              style: TextStyle(color: fgMuted, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Redigera',
              icon: const Icon(Icons.settings_outlined, color: fgMuted),
              onPressed: () => Navigator.pop(ctx, _ViewAction.edit),
            ),
          ],
        ),
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: fgMuted,
                  ),
                ),
              if (note.title.isNotEmpty) const SizedBox(height: 12),
              Text(
                note.text,
                style: const TextStyle(color: fgMuted, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // --- Images (thumbnails + tap to preview) ---
              if (note.imagePaths.isNotEmpty) ...[
                Text(
                  'Bilder',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelLarge?.copyWith(color: fgMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: note.imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = note.imagePaths[i];
                      return GestureDetector(
                        onTap: () => _showImageViewer(
                          context,
                          note.imagePaths,
                          initialIndex: i,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(p),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 96,
                              height: 96,
                              color: Colors.black26,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (note.videoPaths.isNotEmpty) ...[
                Text(
                  'Video',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: note.videoPaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final thumb = (i < note.videoThumbPaths.length)
                          ? note.videoThumbPaths[i]
                          : null;
                      return GestureDetector(
                        onTap: () =>
                            _showVideoPlayer(context, note.videoPaths[i]),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: thumb != null && thumb.isNotEmpty
                                  ? Image.file(
                                      File(thumb),
                                      width: 160,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _thumbFallback(),
                                    )
                                  : _thumbFallback(),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, _ViewAction.close),
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(
                    Colors.blueGrey,
                  ),
                ),
                child: const Text(
                  'Stäng',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (action != _ViewAction.edit) return null;

  // Forward to the edit dialog (which can also add/remove images)
  return showEditNoteDialog(
    context: context,
    note: note,
    onAddImages: onAddImages,
    onRemoveImage: onRemoveImage,
    onAddVideos: onAddVideos,
    onRemoveVideo: onRemoveVideo,
  );
}

/// Full-screen, swipeable, pinch-zoom image viewer
void _showImageViewer(
  BuildContext context,
  List<String> paths, {
  int initialIndex = 0,
}) {
  final controller = PageController(initialPage: initialIndex);
  showDialog(
    context: context,
    barrierColor: Colors.black..withValues(alpha: 0.9),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: paths.length,
            itemBuilder: (_, i) {
              final file = File(paths[i]);
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}

// helper
Widget _thumbFallback() => Container(
  width: 160,
  height: 96,
  color: Colors.black26,
  alignment: Alignment.center,
  child: const Icon(Icons.videocam_outlined, color: Colors.white70),
);

void _showVideoPlayer(BuildContext context, String path) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.9),
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
        setState(() => _ready = true);
        _ctl.play();
      });
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: _ready ? _ctl.value.aspectRatio : 16 / 9,
            child: _ready
                ? VideoPlayer(_ctl)
                : const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Play/pause tap
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!_ready) return;
                  if (_ctl.value.isPlaying) {
                    _ctl.pause();
                  } else {
                    _ctl.play();
                  }
                  setState(() {});
                },
              ),
            ),
          ),
          // Simple scrub progress
          if (_ready)
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: VideoProgressIndicator(
                _ctl,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
