import 'dart:math' as math;

class FFT {
  final int n;
  final List<int> _bitrev;
  final List<double> _cos;
  final List<double> _sin;

  FFT(this.n)
      : assert((n & (n - 1)) == 0),
        _bitrev = _buildBitRev(n),
        _cos = List<double>.filled(n ~/ 2, 0),
        _sin = List<double>.filled(n ~/ 2, 0) {
    for (int i = 0; i < n ~/ 2; i++) {
      _cos[i] = math.cos(-2 * math.pi * i / n);
      _sin[i] = math.sin(-2 * math.pi * i / n);
    }
  }

  static List<int> _buildBitRev(int n) {
    int log2n = (math.log(n) / math.log(2)).round();
    final rev = List<int>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      int x = i, y = 0;
      for (int j = 0; j < log2n; j++) { y = (y << 1) | (x & 1); x >>= 1; }
      rev[i] = y;
    }
    return rev;
  }

  void fft(List<double> re, List<double> im) {
    final n = this.n;
    for (int i = 0; i < n; i++) {
      int j = _bitrev[i];
      if (j > i) { final tr = re[i]; re[i] = re[j]; re[j] = tr; final ti = im[i]; im[i] = im[j]; im[j] = ti; }
    }
    for (int s = 1; (1 << s) <= n; s++) {
      int m = 1 << s;
      int m2 = m >> 1;
      int step = n ~/ m;
      for (int k = 0; k < n; k += m) {
        for (int j = 0; j < m2; j++) {
          int idx = j * step;
          double wr = _cos[idx], wi = _sin[idx];
          double tr = wr * re[k + j + m2] - wi * im[k + j + m2];
          double ti = wr * im[k + j + m2] + wi * re[k + j + m2];
          re[k + j + m2] = re[k + j] - tr;
          im[k + j + m2] = im[k + j] - ti;
          re[k + j] += tr; im[k + j] += ti;
        }
      }
    }
  }

  void ifft(List<double> re, List<double> im) {
    for (int i = 0; i < n; i++) im[i] = -im[i];
    fft(re, im);
    final invN = 1.0 / n;
    for (int i = 0; i < n; i++) { re[i] *= invN; im[i] = -im[i] * invN; }
  }
}
