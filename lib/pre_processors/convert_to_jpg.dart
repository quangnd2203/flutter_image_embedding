import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts an image file (any format) to JPEG bytes.
Future<Uint8List> convertImageFileToJpgBytes(File file) async {
  final extension = file.path.toLowerCase().split('.').last;
  if (extension != 'png') {
    return file.readAsBytes();
  }

  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    return bytes;
  }

  final jpgBytes = Uint8List.fromList(img.encodeJpg(image));
  return jpgBytes;
}
