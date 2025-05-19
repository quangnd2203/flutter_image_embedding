import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:characters/characters.dart';

class SimpleTokenizer {
  final Map<String, int> encoder;
  final Map<int, String> decoder;
  final Map<dynamic, int> bpeRanks;
  final Map<String, String> cache = {
    "<|startoftext|>": "<|startoftext|>",
    "<|endoftext|>": "<|endoftext|>",
  };
  final RegExp pat = RegExp(
    r"""<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]+|[^\s\p{L}\p{N}]+""",
    caseSensitive: false,
    unicode: true,
  );
  final Map<int, String> byteEncoder;
  final Map<String, int> byteDecoder;

  SimpleTokenizer._(this.encoder, this.decoder, this.bpeRanks, this.byteEncoder, this.byteDecoder);

  /// Loads the BPE tokenizer from an asset file and initializes the tokenizer.
  ///
  /// This function does the following:
  /// 1. Reads a vocabulary file from the asset bundle.
  /// 2. Parses merge rules used in Byte Pair Encoding (BPE).
  /// 3. Builds a vocabulary list including:
  ///    - base Unicode characters from byte-to-Unicode mapping,
  ///    - tokens with `</w>` denoting end-of-word markers,
  ///    - BPE merge pairs,
  ///    - special tokens `<|startoftext|>` and `<|endoftext|>`.
  /// 4. Constructs encoder (token to ID) and decoder (ID to token) maps.
  /// 5. Creates a map of BPE merge pair rankings.
  /// 6. Returns a fully initialized `SimpleTokenizer` instance.
  ///
  /// [vocabAssetPath] - The path to the vocab file in assets.
  /// Returns a [Future] that completes with an instance of [SimpleTokenizer].
  static Future<SimpleTokenizer> fromAsset(String vocabAssetPath) async {
    // Load the BPE vocab file from assets
    final bpeContent = await rootBundle.loadString(vocabAssetPath);

    // Split the content into lines
    final lines = LineSplitter.split(bpeContent).toList();

    // Extract the BPE merge lines: skip header and limit to specific range used in CLIP
    final mergeLines = lines.sublist(1, 49152 - 256 - 2 + 1);

    // Convert each line to a tuple of merge pairs (e.g., ['t', 'h'] => ('t', 'h'))
    final merges = mergeLines
        .map((line) => line.split(' '))
        .where((pair) => pair.length == 2)
        .map((pair) => (pair[0], pair[1]))
        .toList();

    // Create byte-to-unicode mapping used for encoding bytes as characters
    final byteUnicode = _bytesToUnicode();

    // Build the vocabulary list including base tokens, end-of-word tokens, merge tokens, and special tokens
    final vocab = <String>[
      ...byteUnicode.values,
      ...byteUnicode.values.map((v) => '$v</w>'),
      ...merges.map((e) => e.$1 + e.$2),
      '<|startoftext|>',
      '<|endoftext|>',
    ];

    // Assign each token in the vocab a unique integer index
    final encoder = <String, int>{for (var i = 0; i < vocab.length; i++) vocab[i]: i};

    // Create the reverse mapping for decoding
    final decoder = {for (var entry in encoder.entries) entry.value: entry.key};

    // Map each BPE merge pair to its rank (lower rank = higher priority)
    final bpeRanks = {for (var i = 0; i < merges.length; i++) merges[i]: i};

    // Return a constructed tokenizer
    return SimpleTokenizer._(
      encoder,
      decoder,
      bpeRanks,
      byteUnicode,
      {for (var e in byteUnicode.entries) e.value: e.key},
    );
  }

  /// Encodes a given input text string into a list of integer tokens using BPE.
  ///
  /// The input is normalized, tokenized using regex, then each token is encoded
  /// as UTF-8, mapped through the byte encoder, and BPE encoded.
  ///
  /// Returns a list of token integers.
  List<int> encode(String text) {
    final tokens = <int>[];
    final normText = text.toLowerCase();
    final matches = pat.allMatches(normText).map((m) => m.group(0)!).toList();
    for (final token in matches) {
      final encoded = utf8.encode(token).map((b) => byteEncoder[b]!).join();
      final bpeTokens = _bpe(encoded).split(' ');
      tokens.addAll(bpeTokens.map((t) => encoder[t]!));
    }
    return tokens;
  }

  /// Finds the bigram with the lowest rank based on the BPE merge rules.
  ///
  /// Returns the pair with the smallest rank or null if none found.
  (String, String)? minBigram(Set<(String, String)> pairs, Map<dynamic, int> ranks) {
    (String, String)? minPair;
    int minRank = 1 << 30;
    for (var pair in pairs) {
      final rank = ranks[pair] ?? (1 << 30);
      if (rank < minRank) {
        minRank = rank;
        minPair = pair;
      }
    }
    return minPair;
  }

  /// Applies Byte Pair Encoding (BPE) to a given token string.
  ///
  /// Splits the token into characters, applies BPE merge operations based on ranking,
  /// and caches the result for future reuse.
  ///
  /// Returns a string of merged BPE tokens separated by space.
  String _bpe(String token) {
    if (cache.containsKey(token)) return cache[token]!;
    // Split token into chars, then add </w> to the last char
    final chars = token.characters.toList();
    if (chars.isEmpty) return '';
    chars[chars.length - 1] = chars.last + '</w>';
    var word = List<String>.from(chars);
    var pairs = _getPairs(word);
    if (pairs.isEmpty) {
      return '$token</w>';
    }
    while (true) {
      final bigram = minBigram(pairs, bpeRanks);
      if (bigram == null || !bpeRanks.containsKey(bigram)) break;
      final first = bigram.$1;
      final second = bigram.$2;
      final newWord = <String>[];
      var i = 0;
      while (i < word.length) {
        final j = word.indexOf(first, i);
        if (j == -1) {
          newWord.addAll(word.sublist(i));
          break;
        }
        newWord.addAll(word.sublist(i, j));
        i = j;
        if (i < word.length - 1 && word[i] == first && word[i + 1] == second) {
          newWord.add(first + second);
          i += 2;
        } else {
          newWord.add(word[i]);
          i += 1;
        }
      }
      word = newWord;
      if (word.length == 1) break;
      pairs = _getPairs(word);
    }
    return cache[token] = word.join(' ');
  }

  /// Extracts all adjacent pairs of symbols from a word represented as a list of strings.
  ///
  /// Returns a set of (String, String) pairs.
  Set<(String, String)> _getPairs(List<String> word) {
    final pairs = <(String, String)>{};
    for (var i = 0; i < word.length - 1; i++) {
      pairs.add((word[i], word[i + 1]));
    }
    return pairs;
  }

  /// Constructs a reversible mapping from bytes (0-255) to Unicode strings.
  ///
  /// Ensures that all byte values are mapped to printable Unicode characters.
  ///
  /// Returns a map from integer byte values to unique Unicode characters.
  static Map<int, String> _bytesToUnicode() {
    final bs = [...List.generate(94, (i) => i + 33), ...List.generate(78, (i) => i + 161)];
    final cs = [...bs];
    int n = 0;
    for (var b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n++;
      }
    }
    return Map.fromIterables(bs, cs.map((c) => String.fromCharCode(c)));
  }
}