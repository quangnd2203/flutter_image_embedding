import 'package:flutter/services.dart';
import 'package:flutter_image_embedding/clip_models/clip_image_visual_model.dart';
import 'package:flutter_image_embedding/clip_models/clip_model_interface.dart';
import 'package:flutter_test/flutter_test.dart';



void main() async {

  TestWidgetsFlutterBinding.ensureInitialized();

  late final ClipModelInterface model;

  setUpAll(() async {
    model = ClipImageVisualModel();
    await model.loadModel();
  });

  tearDownAll(() {
    model.dispose();
  });

  group('ClipTextTransformerModel', () {
    test('1. should be a subclass of ClipModelInterface', () {
      expect(model, isA<ClipModelInterface>());
    });

    test('4. extractTextEmbedding should return a list of doubles', () async {
      final byteData = await rootBundle.load('assets/images/1.jpg');
      final data =  byteData.buffer.asUint8List();
      final result = await model.extractImageEmbedding([data]);
      print(result);
    });
  });
}