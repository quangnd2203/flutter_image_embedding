import 'package:hive_ce/hive.dart';

class VectorImage extends HiveObject {
  final String imageName;
  final List<double> vector;

  VectorImage({required this.imageName, required this.vector});
}