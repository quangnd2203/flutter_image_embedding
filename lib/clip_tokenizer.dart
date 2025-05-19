import 'package:flutter_image_embedding/tokenizer.dart';

/// A tokenizer class for CLIP models using a BPE-based vocabulary.
/// Provides batching and padding logic for text tokenization compatible with CLIP input format.
class ClipTokenizer {

  late final SimpleTokenizer _tokenizer;

  /// Initializes the tokenizer by loading a BPE vocabulary file from assets.
  ///
  /// Returns:
  ///   A [ClipTokenizer] instance with an initialized [SimpleTokenizer].
  ///
  /// Throws:
  ///   An exception if the tokenizer file cannot be loaded.
  Future<ClipTokenizer> create() async {
    _tokenizer = await SimpleTokenizer.fromAsset('assets/tokenizer/bpe_simple_vocab_16e6.txt');
    return this;
  }

  /// Tokenizes a batch of input strings into padded token ID sequences for CLIP input.
  ///
  /// Each text is prepended with the start-of-text token and appended with the end-of-text token.
  /// If the tokenized result exceeds [contextLength], it is either truncated or an exception is thrown.
  ///
  /// Parameters:
  ///   - [texts]: A list of input strings to tokenize.
  ///   - [contextLength]: Desired fixed length of each token sequence (default: 77).
  ///   - [truncate]: Whether to truncate sequences that exceed [contextLength] (default: false).
  ///
  /// Returns:
  ///   A list of token ID lists, each of length [contextLength].
  ///
  /// Throws:
  ///   An exception if [truncate] is false and a tokenized input exceeds [contextLength].
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
