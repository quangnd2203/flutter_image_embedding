import 'package:flutter/material.dart';
import '../assets_list.dart';

class ImageList extends StatelessWidget {
  final bool Function(String)? filter;
  final Comparator<String>? sort;

  const ImageList({super.key, this.filter, this.sort});

  @override
  Widget build(BuildContext context) {
    List<String> filteredImages = filter == null
        ? List.from(assetImages)
        : assetImages.where(filter!).toList();

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
        return Image.asset(
          filteredImages[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}