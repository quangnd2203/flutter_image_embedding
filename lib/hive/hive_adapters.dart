import 'package:flutter_image_embedding/vector_image.dart';
import 'package:hive_ce/hive.dart';


part 'hive_adapters.g.dart';

@GenerateAdapters(<AdapterSpec<dynamic>>[
  AdapterSpec<VectorImage>(),
])

class HiveAdapters {
  static const String vectorImageBox = 'vectorImageBox';
}