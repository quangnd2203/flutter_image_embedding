enum ClipModels {
  clip('assets/onnx/clip.onnx'), // CLIP
  clipImageVisual('assets/onnx/clip_image_visual.onnx'), // CLIP_IMAGE_VISUAL
  clipTextTransformer('assets/onnx/clip_text_transformer.onnx'); // CLIP_TEXT_TRANSFORMER

  final String path;
  const ClipModels(this.path);
}