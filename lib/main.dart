import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_image_embedding/clip_model_interface.dart';
import 'package:flutter_image_embedding/hive/hive_adapters.dart';
import 'package:flutter_image_embedding/hive/hive_registrar.g.dart';
import 'package:flutter_image_embedding/vector_image.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_embedding/widget/image_list.dart';
import 'package:photo_manager/photo_manager.dart';

import 'assets_list.dart';
import 'clip_image_visual_model.dart';
import 'cosine_similarity.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapters();
  await Hive.openBox<VectorImage>(HiveAdapters.vectorImageBox);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _selectedImage;
  List<double>? _selectedVector;
  bool _isLoading = false;

  final Map<String, VectorImage> vectorImages = {};

  ClipModelInterface model = ClipImageVisualModel();

  final StreamController<int> processImagesController = StreamController<int>.broadcast();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      final bytes = await imageFile.readAsBytes();
      final vector = await model.extractImageEmbedding([bytes]);
      setState(() {
        _selectedImage = imageFile;
        _selectedVector = vector[0];
      });
    }
  }

  Future<void> _preVectorImages() async {
    setState(() {
      _isLoading = true;
    });

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _selectedImage = null;
    _selectedVector = null;

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
    );
    final List<AssetEntity> assets = await paths.first.getAssetListRange(start: 0, end: 100);

    const batchSize = 5;
    for (int i = 0; i < assets.length; i += batchSize) {
      final batch = assets.sublist(i, (i + batchSize > assets.length) ? assets.length : i + batchSize);

      final preProcessImages = await Future.wait(
        batch.map((file) async {
          final bytes = await (await file.file)!.readAsBytes();
          return bytes;
        }),
      );
      final vectors = await model.extractImageEmbedding(preProcessImages);

      for (int j = 0; j < batch.length; j++) {
        final file = batch[j];
        final vectorImage = VectorImage(
          imageName: (await file.originFile)!.path,
          vector: vectors[j],
        );
        vectorImages[(await file.originFile)!.path] = vectorImage;
        final currentIndex = i + j + 1;
        final progressPercent = (currentIndex / assets.length * 100).clamp(0, 100).round();
        processImagesController.add(progressPercent);
      }
      preProcessImages.clear();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    model.loadModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Row(
                  children: [
                    Expanded(child: Image.file(_selectedImage!, height: 200)),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _selectedVector = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Expanded(
                child: ImageList(
                  images: vectorImages.keys.toList(),
                  filter: (String image) {
                    if (_selectedVector == null) {
                      return true;
                    }

                    final vector = vectorImages[image]!.vector;
                    final distance = cosineSimilarity(
                      _selectedVector!,
                      vector,
                    );

                    return distance < 0.5;
                  },
                  sort: _selectedVector == null
                      ? null
                      : (a, b) {
                          final va = vectorImages[a]!.vector;
                          final vb = vectorImages[b]!.vector;
                          final sa = cosineSimilarity(_selectedVector!, va);
                          final sb = cosineSimilarity(_selectedVector!, vb);
                          return sa.compareTo(sb); // Higher similarity = comes first
                        },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: StreamBuilder<int>(
                  stream: processImagesController.stream,
                  builder: (context, snapshot) {
                    final percent = snapshot.data ?? 0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 20)),
                      ],
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickImage,
            tooltip: 'Upload',
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _preVectorImages,
            tooltip: vectorImages.isEmpty ? 'Init' : 'Refresh',
            child: Icon(vectorImages.isEmpty ? Icons.play_arrow : Icons.refresh),
          ),
        ],
      ),
    );
  }
}
