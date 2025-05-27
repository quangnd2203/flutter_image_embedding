import 'package:flutter/services.dart';
import 'package:flutter_image_embedding/pre_processors/clip_preprocess.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_embedding/pre_processors/clip_tokenizer.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  late final ClipTokenizer tokenizer;

  setUpAll(() async {
    tokenizer = ClipTokenizer();
    await tokenizer.create();
  });

  group('ClipTokenizer', () {
    testWidgets('should include start and end tokens', (tester) async {
      final tokens = tokenizer.tokenizeBatch(['a photo with dog']);
      expect(tokens.length, 1);
      expect(tokens[0].length, 77);
    });
  });

  group('ClipPreprocessor', () {
    testWidgets('pre process image2', (tester) async {
      final byteData = await rootBundle.load('assets/images/1.jpg');
      final data =  byteData.buffer.asUint8List();
      final result = preprocessClipImage(data);
    });
  });
}
