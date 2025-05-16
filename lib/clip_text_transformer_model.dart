// import 'dart:typed_data';
// import 'package:onnxruntime/onnxruntime.dart';
// import 'package:flutter/services.dart' show rootBundle;
//
// import 'clip_model_interface.dart';
//
// class ClipTextTransformerModel implements ClipModelInterface {
//   late OrtSession _session;
//
//   @override
//   Future<void> loadModel() async {
//     final sessionOptions = OrtSessionOptions();
//     final rawAssetFile = await rootBundle.load('assets/onnx/clip_text_transformer.onnx');
//     final bytes = rawAssetFile.buffer.asUint8List();
//     _session = OrtSession.fromBuffer(bytes, sessionOptions);
//   }
//
//   @override
//   Future<List<double>> extractTextEmbedding(String text) async {
//     // Tokenization must be provided externally; here it's mocked as a fixed shape of 77 tokens.
//     // In production, integrate real tokenizer.
//     final tokenIds = List<int>.filled(77, 0); // TODO: replace with real token IDs
//     final input = OrtValueTensor.createTensorWithDataList(tokenIds, [1, 77]);
//     final outputs = await _session.runAsync({'TEXT': input});
//     final result = outputs['FEATURES_EMBEDDED'] as OrtValueTensor;
//     return result.data.cast<double>();
//   }
//
//   @override
//   Future<List<double>> extractImageEmbedding(Uint8List imageBytes) {
//     throw UnsupportedError('extractImageEmbedding is not supported in ClipTextTransformerModel');
//   }
//
//   @override
//   void dispose() {
//     _session.release();
//   }
// }