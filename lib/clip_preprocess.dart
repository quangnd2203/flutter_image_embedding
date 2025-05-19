import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Preprocesses an input image for CLIP model inference.
/// - Decodes and resizes the image to 224x224.
/// - Normalizes RGB channels using CLIP-specific mean and std.
/// - Returns a [3][224][224] list representing the tensor format.
List<List<List<double>>> preprocessImage(Uint8List imageBytes) {

  // Decode the image bytes
  final image = img.decodeImage(imageBytes)!;

  // Resize to 224x224
  final resized = centerCrop(resizeByShortSide(image, 224), 224);

  // Normalization values for CLIP model
  final mean = [0.48145466, 0.4578275, 0.40821073];
  final std = [0.26862954, 0.26130258, 0.27577711];

  // Initialize tensor shape [3][224][224]
  final List<List<List<double>>> tensor = List.generate(
    3,
    (_) => List.generate(224, (_) => List.filled(224, 0.0)),
  );

  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = resized.getPixel(x, y);
      final r = pixel.r / 255.0;
      final g = pixel.g / 255.0;
      final b = pixel.b / 255.0;

      tensor[0][y][x] = (r - mean[0]) / std[0]; // Red
      tensor[1][y][x] = (g - mean[1]) / std[1]; // Green
      tensor[2][y][x] = (b - mean[2]) / std[2]; // Blue
    }
  }

  return tensor;
}

img.Image resizeByShortSide(img.Image src, int targetShort) {
  final srcWidth = src.width;
  final srcHeight = src.height;

  final isPortrait = srcHeight < srcWidth;
  final scale = targetShort / (isPortrait ? srcHeight : srcWidth);

  final newWidth = (srcWidth * scale).round();
  final newHeight = (srcHeight * scale).round();

  return img.copyResize(
    src,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.cubic,
  );
}

img.Image centerCrop(img.Image src, int size) {
  final offsetX = ((src.width - size) / 2).round();
  final offsetY = ((src.height - size) / 2).round();
  return img.copyCrop(
    src,
    x: offsetX,
    y: offsetY,
    width: size,
    height: size,
  );
}