import 'dart:typed_data';

abstract class ClipModelInterface {
  Future<void> loadModel();
  Future<List<List<double>>> extractImageEmbedding(List<Uint8List> images);
  Future<List<List<double>>> extractTextEmbedding(List<String> texts);
  void dispose();
}
