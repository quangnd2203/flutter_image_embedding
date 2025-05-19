enum ClipModels {
  clip('assets/onnx/clip_model.onnx'), // CLIP
  clipImageVisual('assets/onnx/clip_model_visual.onnx'), // CLIP_IMAGE_VISUAL
  clipTextTransformer('assets/onnx/clip_model_transformer.onnx'); // CLIP_TEXT_TRANSFORMER

  final String path;
  const ClipModels(this.path);
}