import 'dart:typed_data';

abstract class ClipModelInterface {
  Future<void> loadModel();
  Future<List<double>> extractImageEmbedding(Uint8List imageBytes);
  Future<List<double>> extractTextEmbedding(String text);
  void dispose();
}
