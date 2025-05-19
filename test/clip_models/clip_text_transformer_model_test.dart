// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_image_embedding/clip_text_transformer_model.dart';
//
// import 'package:flutter_image_embedding/clip_model_interface.dart';
//
//
// void main() async {
//
//   TestWidgetsFlutterBinding.ensureInitialized();
//
//   late final ClipModelInterface model;
//
//   setUpAll(() async {
//     model = ClipTextTransformerModel();
//     await model.loadModel();
//   });
//
//   tearDownAll(() {
//     model.dispose();
//   });
//
//   group('ClipTextTransformerModel', () {
//     test('1. should be a subclass of ClipModelInterface', () {
//       expect(model, isA<ClipModelInterface>());
//     });
//
//     test('4. extractTextEmbedding should return a list of doubles', () async {
//       final result = await model.extractTextEmbedding(['a photo with dog', 'a photo with cat']);
//       print(result.length);
//     });
//   });
// }