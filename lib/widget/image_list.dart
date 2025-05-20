import 'package:flutter/material.dart';
import 'dart:io';

class ImageList extends StatelessWidget {
  final List<String> images;
  final bool Function(String)? filter;
  final Comparator<String>? sort;

  const ImageList({
    super.key,
    required this.images,
    this.filter,
    this.sort,
  });

  @override
  Widget build(BuildContext context) {
    List<String> filteredImages = filter == null
        ? List.from(images)
        : images.where(filter!).toList();

    if (sort != null) {
      filteredImages.sort(sort);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredImages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        return Image.file(
          File(filteredImages[index]),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 300, // giảm kích thước cache nếu cần
        );
      },
    );
  }
}