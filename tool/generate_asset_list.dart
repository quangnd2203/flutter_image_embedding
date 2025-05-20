import 'dart:io';

void main() {
  final dir = Directory('assets/images');
  final output = File('lib/assets_list.dart');

  final buffer = StringBuffer();
  buffer.writeln('// 🔥 This file is auto-generated. Do not edit by hand.');
  buffer.writeln('const List<String> assetImages = [');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File &&
        ['.png', '.jpg', '.jpeg', '.webp', '.gif'].any((ext) => entity.path.toLowerCase().endsWith(ext))) {
      final relativePath = entity.path.replaceAll('\\', '/');
      buffer.writeln("  '$relativePath',");
    }
  }

  buffer.writeln('];');

  output.writeAsStringSync(buffer.toString());
  print('✅ assetImages list generated with ${buffer.length} bytes.');
}