
import 'package:flutter_image_embedding/tokenizer.dart';

class ClipTokenizer {

  late final SimpleTokenizer _tokenizer;

  Future<ClipTokenizer> create() async {
    _tokenizer = await SimpleTokenizer.fromAsset('assets/tokenizer/bpe_simple_vocab_16e6.txt');
    return this;
  }

  List<List<int>> tokenizeBatch(
      List<String> texts, {
        int contextLength = 77,
        bool truncate = false,
      }) {
    final int sotToken = _tokenizer.encoder["<|startoftext|>"]!;
    final int eotToken = _tokenizer.encoder["<|endoftext|>"]!;
    final List<List<int>> result = [];

    for (final text in texts) {
      List<int> tokens = [sotToken, ..._tokenizer.encode(text), eotToken];

      if (tokens.length > contextLength) {
        if (truncate) {
          tokens = tokens.sublist(0, contextLength);
          tokens[contextLength - 1] = eotToken;
        } else {
          throw Exception("Input \"$text\" is too long for context length $contextLength");
        }
      }

      // Pad with zeros
      final padded = List<int>.filled(contextLength, 0);
      for (int i = 0; i < tokens.length; i++) {
        padded[i] = tokens[i];
      }
      result.add(padded);
    }

    return result;
  }

}
