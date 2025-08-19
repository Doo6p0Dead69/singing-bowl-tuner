import 'dart:math' as math;

List<double> blackmanHarris(int n) {
  const a0 = 0.35875;
  const a1 = 0.48829;
  const a2 = 0.14128;
  const a3 = 0.01168;
  final w = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    final t = 2 * math.pi * i / (n - 1);
    w[i] = a0 - a1 * math.cos(t) + a2 * math.cos(2*t) - a3 * math.cos(3*t);
  }
  return w;
}
