import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:gk_notes/core/image_compress.dart';
import 'package:gk_notes/data/models/image_to_attach.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Result returned by any attach-videos call.
typedef VideoAttachResult = ({
  List<String> videoPaths,
  List<String> thumbPaths,
});

/// Handles all file-system work for note attachments:
/// copying, compressing, thumbnail generation, and deletion.
/// Returns the new file paths — it never touches app state.
class MediaService {
  Future<Directory> _noteDir(String id) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/notes/$id');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _stamp([String ext = '.jpg']) =>
      '${DateTime.now().microsecondsSinceEpoch}$ext';

  // ------------------------------------------------------------------ images

  /// Saves [imgs] (raw bytes) into the note folder after compression.
  /// Returns the list of newly written file paths.
  Future<List<String>> saveImagesFromBytes(
    String id,
    List<ImageToAttach> imgs,
  ) async {
    if (imgs.isEmpty) return const [];
    final dir = await _noteDir(id);
    final added = <String>[];
    for (final img in imgs) {
      final compressed = await compressImageBytes(
        img.bytes,
        maxDimension: 1600,
        quality: 82,
      );
      final dest = File('${dir.path}/${_stamp(img.ext)}');
      await dest.writeAsBytes(compressed, flush: true);
      added.add(dest.path);
    }
    return added;
  }

  /// Opens the system image picker and saves chosen images.
  /// Returns newly written file paths, or an empty list if cancelled.
  Future<List<String>> pickAndSaveImages(String id) async {
    final dir = await _noteDir(id);
    final added = <String>[];

    // Prefer image_picker (best UX on Android/iOS).
    try {
      final picks = await ImagePicker().pickMultiImage(imageQuality: 100);
      for (final x in picks) {
        final bytes = await File(x.path).readAsBytes();
        final compressed = await compressImageBytes(
          bytes,
          maxDimension: 1600,
          quality: 82,
        );
        final dest = File('${dir.path}/${_stamp()}');
        await dest.writeAsBytes(compressed, flush: true);
        added.add(dest.path);
      }
    } on PlatformException {
      // Fall through to file_picker below.
    } catch (_) {
      // Fall through to file_picker below.
    }

    // Fallback: file_picker (works when image_picker channel is unavailable).
    if (added.isEmpty) {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (res != null) {
        for (final f in res.files) {
          final Uint8List? bytes =
              f.bytes ??
              (f.path != null ? await File(f.path!).readAsBytes() : null);
          if (bytes == null) continue;
          final compressed = await compressImageBytes(
            bytes,
            maxDimension: 1600,
            quality: 82,
          );
          final dest = File('${dir.path}/${_stamp()}');
          await dest.writeAsBytes(compressed, flush: true);
          added.add(dest.path);
        }
      }
    }

    return added;
  }

  /// Deletes [path] from disk. Errors are silently ignored.
  Future<void> deleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ------------------------------------------------------------------ videos

  Future<VideoAttachResult> _copyAndThumbVideos(
    String id,
    List<String> srcPaths,
  ) async {
    final dir = await _noteDir(id);
    final videos = <String>[];
    final thumbs = <String>[];

    for (final src in srcPaths) {
      if (src.isEmpty) continue;
      final ext = p.extension(src).isNotEmpty ? p.extension(src) : '.mp4';
      final dest = File('${dir.path}/${_stamp(ext)}');
      await File(src).copy(dest.path);

      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: dest.path,
        thumbnailPath: dir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 320,
        quality: 82,
      );

      videos.add(dest.path);
      thumbs.add(thumbPath ?? '');
    }

    return (videoPaths: videos, thumbPaths: thumbs);
  }

  /// Opens the system video picker, copies chosen files, generates thumbnails.
  Future<VideoAttachResult> pickAndSaveVideos(String id) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
      withData: false,
    );
    if (res == null || res.files.isEmpty) {
      return (videoPaths: <String>[], thumbPaths: <String>[]);
    }

    final srcPaths = res.files
        .map((f) => f.path ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return _copyAndThumbVideos(id, srcPaths);
  }

  /// Copies [srcPaths] into the note folder and generates thumbnails.
  Future<VideoAttachResult> saveVideosFromPaths(
    String id,
    List<String> srcPaths,
  ) => _copyAndThumbVideos(id, srcPaths);

  // ------------------------------------------------------------------ PDFs

  Future<List<String>> _copyPdfs(String id, List<String> srcPaths) async {
    if (srcPaths.isEmpty) return const [];
    final dir = await _noteDir(id);
    final added = <String>[];
    for (final src in srcPaths) {
      final dest = File('${dir.path}/${_stamp('.pdf')}');
      await File(src).copy(dest.path);
      added.add(dest.path);
    }
    return added;
  }

  /// Opens the system file picker and copies chosen PDFs.
  Future<List<String>> pickAndSavePdfs(String id) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: false,
    );
    if (res == null || res.files.isEmpty) return const [];

    final srcPaths = res.files
        .map((f) => f.path ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    return _copyPdfs(id, srcPaths);
  }

  /// Copies [srcPaths] into the note folder.
  Future<List<String>> savePdfsFromPaths(String id, List<String> srcPaths) =>
      _copyPdfs(id, srcPaths);
}
