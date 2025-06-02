# flutter_image_embedding

<p align="center">
  <img src="assets/gif/demo.gif" width="600" alt="App demo"/>
</p>

A new Flutter project.

## Getting Started

### ⚙️ iOS Release Build Fix: Strip Style (TFLite / ONNXRuntime)

> ❗️When building IPA release, the app might crash with `Failed to lookup symbol` or `Symbol not found: _OrtGetApiBase` due to Xcode stripping native C symbols.

🔧 **How to fix:**

1. Open Xcode
2. Select the `Runner` target
3. Go to `Build Settings`
4. Search for `Strip Style`
5. 👉 Change from `All Symbols` to `Non-Global Symbols`

> ✅ This keeps required global C symbols used by libraries like TFLite or ONNXRuntime (which rely on `dlsym()`).

📌 Apply this to both `Release` and `Profile` configurations.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# flutter_image_embedding

`flutter_image_embedding` is a Flutter plugin that provides on-device image and text embedding functionality using ONNX models, such as OpenAI's CLIP. This allows developers to extract image and text features and perform similarity matching directly in their Flutter apps.

## Features

- Embed images using a CLIP image encoder ONNX model
- Embed texts using a CLIP text transformer ONNX model
- Tokenize input text using a custom tokenizer compatible with CLIP
- Perform image-to-text or image-to-image similarity matching
- Lightweight and optimized for on-device inference

## Getting Started

### Prerequisites

- Flutter 3.3 or higher
- Dart SDK 3.6.1 or higher
- Download the ONNX models from [this Google Drive link](https://drive.google.com/drive/folders/1ZA0463DyGqe2dYy5pkI5X3SK0B8guwHA?usp=sharing) and place them in `assets/onnx/`:
  - `clip_model.onnx`
  - `clip_model_transformer.onnx`
  - `clip_model_visual.onnx`
- Vocabulary file: `assets/tokenizer/vocab.txt`

### Usage

## Tokenizer

This package includes a CLIP-compatible BPE tokenizer written in Dart. It uses `vocab.txt` and applies BPE merging to match CLIP's tokenization.

## First Run Project

To generate necessary code and ensure the project builds correctly, run:

```bash
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## License

This project uses open models and is provided under the MIT License.