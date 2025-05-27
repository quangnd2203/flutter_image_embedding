import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Converts an image file (any format) to JPEG bytes.
Future<Uint8List> convertImageFileToJpgBytes((File file, bool? isPickerImage) params) async {
  final extension = params.$1.path.toLowerCase().split('.').last;
  final isPickerImage = params.$2 ?? false;
  if (extension != 'png' && !isPickerImage) {
    return params.$1.readAsBytes();
  }

  final bytes = await params.$1.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw Exception("Cannot decode image data from file: ${params.$1.path}");
  }

  final jpgBytes = Uint8List.fromList(img.encodeJpg(image));
  return jpgBytes;
}
