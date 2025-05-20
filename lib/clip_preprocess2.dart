

import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Preprocess image to match CLIP input requirements (size, RGB, normalization).
///
/// Returns a 3D tensor with shape [3][224][224] as List<List<List<double>>>,
/// normalized with CLIP mean/std values for each RGB channel.
List<List<List<double>>> preprocessClipImage(Uint8List imageBytes, {int nPx = 224}) {
  // Decode image from bytes
  img.Image? image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception("Cannot decode image data");
  }

  // Resize image so the shortest side == nPx
  int origW = image.width;
  int origH = image.height;
  img.Image resized;
  if (origW < origH) {
    resized = img.copyResize(image, width: nPx, interpolation: img.Interpolation.cubic);
  } else {
    resized = img.copyResize(image, height: nPx, interpolation: img.Interpolation.cubic);
  }

  // Center crop to square nPx x nPx
  int offsetX = (resized.width - nPx) ~/ 2;
  int offsetY = (resized.height - nPx) ~/ 2;
  img.Image cropped = img.copyCrop(resized, x: offsetX, y: offsetY, width: nPx, height: nPx);

  final bytes = cropped.getBytes(order: img.ChannelOrder.rgb);

  List<List<double>> channelR = List.generate(nPx, (_) => List.filled(nPx, 0.0));
  List<List<double>> channelG = List.generate(nPx, (_) => List.filled(nPx, 0.0));
  List<List<double>> channelB = List.generate(nPx, (_) => List.filled(nPx, 0.0));

  int idx = 0;
  for (int y = 0; y < nPx; y++) {
    for (int x = 0; x < nPx; x++) {
      int r = bytes[idx++];
      int g = bytes[idx++];
      int b = bytes[idx++];
      channelR[y][x] = r / 255.0;
      channelG[y][x] = g / 255.0;
      channelB[y][x] = b / 255.0;
    }
  }

  final normalized = normalizeTensor(
    [channelR, channelG, channelB],
    mean: [0.48145466, 0.4578275, 0.40821073],
    std: [0.26862954, 0.26130258, 0.27577711],
  );

  return normalized;
}

/// Normalize a 3D image tensor with shape [3][H][W].
/// Formula: output[c][y][x] = (input[c][y][x] - mean[c]) / std[c]
List<List<List<double>>> normalizeTensor(
  List<List<List<double>>> tensor, {
  required List<double> mean,
  required List<double> std,
}) {
  final int channels = tensor.length;
  final int height = tensor[0].length;
  final int width = tensor[0][0].length;

  final normalized = List.generate(
    channels,
    (c) => List.generate(
      height,
      (y) => List.generate(
        width,
        (x) => (tensor[c][y][x] - mean[c]) / std[c],
      ),
    ),
  );

  return normalized;
}