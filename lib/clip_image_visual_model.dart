import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:flutter_image_embedding/clip_model_interface.dart';

import 'clip_preprocess2.dart';

// Top-level function to preprocess images for compute()
Float32List preprocessImages(List<Uint8List> images) {
  final List<List<List<List<double>>>> imageTensors =
      images.map((img) => preprocessClipImage(img)).toList();

  return Float32List.fromList(
    imageTensors
        .expand((c) => c.expand((h) => h))
        .expand((w) => w)
        .map((e) => e.toDouble())
        .toList(),
  );
}

class ClipImageVisualModel implements ClipModelInterface {
  OrtSession? _session;
  bool _isInitialized = false;

  @override
  Future<void> loadModel() async {
    try{
      if (_isInitialized) return;
      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/onnx/clip_model_visual.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      _isInitialized = true;
    }catch(e){
      print("Error loading model: $e");
      throw Exception("Failed to load model: $e");
    }
  }

  @override
  Future<List<List<double>>> extractImageEmbedding(List<Uint8List> images) async {
    try{
      if (!_isInitialized) {
        throw Exception("Model not loaded. Call loadModel() first.");
      }

      Float32List flattened = await compute(preprocessImages, images);

      final inputTensor = OrtValueTensor.createTensorWithDataList(
        flattened,
        [images.length, 3, 224, 224],
      );
      final runOptions = OrtRunOptions();

      final outputs = await _session?.runAsync(runOptions, {'IMAGE': inputTensor});
      // Release tensor resources to free memory
      inputTensor.release();
      runOptions.release();

      if (outputs == null || outputs.isEmpty || outputs.first == null) {
        return [];
      }
      final OrtValue result = outputs.first!;
      final List<List<double>> data = (result.value as List<List<double>>);

      for (var element in outputs) {
        element?.release();
      }
      flattened = Float32List(0);
      return data;
    }catch (e) {
      print("Error extracting image embedding: $e");
      return [];
    }
  }

  @override
  Future<List<List<double>>> extractTextEmbedding(List<String> texts) {
    throw UnimplementedError("Text embedding is not supported in visual model.");
  }

  @override
  void dispose() {
    _session?.release();
  }
}