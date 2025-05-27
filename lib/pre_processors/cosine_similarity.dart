import 'dart:math';

double cosineSimilarity(List<double> a, List<double> b) {
  assert(a.length == b.length);
  double dotProduct = 0;
  double normA = 0;
  double normB = 0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (sqrt(normA) * sqrt(normB));
}