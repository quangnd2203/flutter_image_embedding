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

  Box<VectorImage> box = Hive.box<VectorImage>(HiveAdapters.vectorImageBox);

  ClipModelInterface model = ClipImageVisualModel();

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

    await box.clear();
    final preProcessImages = await Future.wait(
      assetImages.map((path) async {
        final bytes = await rootBundle.load(path);
        return bytes.buffer.asUint8List();
      }),
    );
    final vectors = await model.extractImageEmbedding(preProcessImages);

    for (int i = 0; i < assetImages.length; i++) {
      final vectorImage = VectorImage(
        imageName: assetImages[i],
        vector: vectors[i],
      );
      await box.put(assetImages[i], vectorImage);
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
              if (_selectedImage != null) Image.file(_selectedImage!, height: 200),
              const SizedBox(height: 10),
              Expanded(
                child: ImageList(
                  filter: (String image) {
                    if (_selectedVector == null) {
                      return true;
                    }

                    final vector = box.get(image)!.vector;
                    final distance = cosineSimilarity(
                      _selectedVector!,
                      vector,
                    );

                    return distance < 0.5;
                  },
                  sort: _selectedVector == null
                      ? null
                      : (a, b) {
                          final va = box.get(a)!.vector;
                          final vb = box.get(b)!.vector;
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
              child: const Center(
                child: CircularProgressIndicator(),
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
          FutureBuilder(
            future: Hive.openBox<VectorImage>(HiveAdapters.vectorImageBox),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              final box = Hive.box<VectorImage>(HiveAdapters.vectorImageBox);
              final isEmpty = box.isEmpty;
              return FloatingActionButton(
                onPressed: _preVectorImages,
                tooltip: isEmpty ? 'Init' : 'Refresh',
                child: Icon(isEmpty ? Icons.play_arrow : Icons.refresh),
              );
            },
          ),
        ],
      ),
    );
  }
}
