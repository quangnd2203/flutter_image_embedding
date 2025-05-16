import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_image_embedding/clip_tokenizer.dart';

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
}
