import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Compresses image bytes to a target max dimension and JPEG quality.
/// - Keeps aspect ratio
/// - Auto-honors EXIF rotation (camera images)
/// - Converts to JPEG (saves lots of space vs PNG; transparency will be flattened)

Future<Uint8List> compressImageBytes(
  Uint8List input, {
  int maxDimension = 1600,
  int quality = 82,
}) async {
  final out = await FlutterImageCompress.compressWithList(
    input,
    format: CompressFormat.jpeg,
    quality: quality,
    minWidth: maxDimension,
    minHeight: maxDimension,
  );
  return Uint8List.fromList(out);
}
