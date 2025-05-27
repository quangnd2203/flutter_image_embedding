import 'dart:typed_data';
import 'package:flutter_image_embedding/pre_processors/clip_tokenizer.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'clip_model_interface.dart';
import 'clip_models.dart';

class ClipTextTransformerModel implements ClipModelInterface {
  late OrtSession _session;

  late ClipTokenizer _tokenizer;

  /// Loads the CLIP text transformer ONNX model from assets and initializes the tokenizer.
  /// This method prepares the ONNX session and tokenizer for embedding extraction.
  @override
  Future<void> loadModel() async {
    final sessionOptions = OrtSessionOptions();
    final rawAssetFile = await rootBundle.load(ClipModels.clipTextTransformer.path);
    final bytes = rawAssetFile.buffer.asUint8List();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);
    _tokenizer = await ClipTokenizer().create();
  }

  /// Extracts a text embedding vector from the given input string.
  ///
  /// This method tokenizes the input text, creates an ONNX tensor of shape [1, 77],
  /// runs inference with the text transformer model, and returns the resulting embedding.
  ///
  /// Returns:
  ///   A list of double values representing the embedded feature vector.
  @override
  Future<List<List<double>>> extractTextEmbedding(List<String> texts) async {
    // Tokenize input text into token ID list
    final List<List<int>> inputConverted = _tokenizer.tokenizeBatch(texts);

    // Flatten the batch of token lists
    final flatTokens = inputConverted.expand((i) => i).toList();
    // Create an ONNX tensor from token list with shape [1, 77]
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Int32List.fromList(flatTokens),
      [texts.length, 77],
    );

    // Run inference on the model with input tensor
    final inputs = {'TEXT': inputTensor};
    final runOptions = OrtRunOptions();
    final outputs = await _session.runAsync(runOptions, inputs);
    // Release tensor resources to free memory
    inputTensor.release();
    runOptions.release();

    if (outputs == null || outputs.isEmpty || outputs.first == null) {
      return [];
    }
    final OrtValue result = outputs.first!;
    final List<List<double>> data = (result.value as List<List<double>>);
    return data;
  }

  /// Throws an error because this model does not support image embeddings.
  ///
  /// This method exists to fulfill the ClipModelInterface contract but will always throw
  /// an UnsupportedError when called.
  @override
  Future<List<List<double>>> extractImageEmbedding(List<Uint8List> images) {
    throw UnsupportedError('extractImageEmbedding is not supported in ClipTextTransformerModel');
  }

  /// Releases the ONNX session to free native memory resources.
  ///
  /// Call this method when the model is no longer needed to avoid memory leaks.
  @override
  void dispose() {
    _session.release();
  }
}