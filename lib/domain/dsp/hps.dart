List<double> harmonicProductSpectrum(List<double> mag, int maxFactor) {
  final n = mag.length;
  final out = List<double>.from(mag);
  for (int factor = 2; factor <= maxFactor; factor++) {
    for (int i = 0; i < n ~/ factor; i++) {
      out[i] *= mag[i * factor];
    }
  }
  return out;
}
