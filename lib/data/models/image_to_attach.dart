import 'dart:typed_data';

class ImageToAttach {
  final Uint8List bytes;
  final String ext; // e.g. ".jpg" or ".png"
  const ImageToAttach(this.bytes, this.ext);
}
