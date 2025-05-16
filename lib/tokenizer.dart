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

  static Future<SimpleTokenizer> fromAsset(String vocabAssetPath) async {
    final bpeContent = await rootBundle.loadString(vocabAssetPath);
    final lines = LineSplitter.split(bpeContent).toList();
    // The first line is a header. Merges start from line 1.
    // According to OpenAI's vocab: merges = lines[1:49152-256-2+1]
    final mergeLines = lines.sublist(1, 49152 - 256 - 2 + 1);
    final merges = mergeLines
        .map((line) => line.split(' '))
        .where((pair) => pair.length == 2)
        .map((pair) => (pair[0], pair[1]))
        .toList();
    final byteUnicode = _bytesToUnicode();
    final vocab = <String>[
      ...byteUnicode.values,
      ...byteUnicode.values.map((v) => '$v</w>'),
      ...merges.map((e) => e.$1 + e.$2),
      '<|startoftext|>',
      '<|endoftext|>',
    ];
    final encoder = <String, int>{for (var i = 0; i < vocab.length; i++) vocab[i]: i};
    final decoder = {for (var entry in encoder.entries) entry.value: entry.key};
    final bpeRanks = {for (var i = 0; i < merges.length; i++) merges[i]: i};
    return SimpleTokenizer._(
      encoder,
      decoder,
      bpeRanks,
      byteUnicode,
      {for (var e in byteUnicode.entries) e.value: e.key},
    );
  }

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

  Set<(String, String)> _getPairs(List<String> word) {
    final pairs = <(String, String)>{};
    for (var i = 0; i < word.length - 1; i++) {
      pairs.add((word[i], word[i + 1]));
    }
    return pairs;
  }

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