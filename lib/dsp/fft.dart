import 'dart:math' as math;

/// Minimal complex number implementation used by the FFT routine.
class ComplexNumber {
  const ComplexNumber(this.real, this.imaginary);

  final double real;
  final double imaginary;

  double get magnitude => math.sqrt(real * real + imaginary * imaginary);

  ComplexNumber operator +(ComplexNumber other) =>
      ComplexNumber(real + other.real, imaginary + other.imaginary);

  ComplexNumber operator -(ComplexNumber other) =>
      ComplexNumber(real - other.real, imaginary - other.imaginary);

  ComplexNumber operator *(ComplexNumber other) => ComplexNumber(
        real * other.real - imaginary * other.imaginary,
        real * other.imaginary + imaginary * other.real,
      );
}

/// In-place radix-2 Cooley-Tukey FFT implementation.  [input] must have a
/// length that is a power of two.  The function returns the complex valued
/// spectrum of [input].
List<ComplexNumber> fftReal(List<double> input) {
  final n = input.length;
  if (n == 0 || (n & (n - 1)) != 0) {
    throw ArgumentError('FFT input size must be a power of two.');
  }
  final data =
      List<ComplexNumber>.generate(n, (i) => ComplexNumber(input[i], 0));
  _fft(data);
  return data;
}

void _fft(List<ComplexNumber> buffer) {
  final n = buffer.length;
  if (n <= 1) {
    return;
  }

  // Bit-reversed addressing permutation.
  var j = 0;
  for (var i = 0; i < n; i++) {
    if (i < j) {
      final temp = buffer[i];
      buffer[i] = buffer[j];
      buffer[j] = temp;
    }
    var m = n >> 1;
    while (j >= m && m >= 2) {
      j -= m;
      m >>= 1;
    }
    j += m;
  }

  // Cooley-Tukey decimation-in-time radix-2 FFT.
  for (var size = 2; size <= n; size <<= 1) {
    final halfSize = size >> 1;
    final tableStep = (2 * math.pi) / size;
    for (var i = 0; i < n; i += size) {
      for (var j = 0; j < halfSize; j++) {
        final angle = tableStep * j;
        final twiddle = ComplexNumber(math.cos(angle), -math.sin(angle));
        final even = buffer[i + j];
        final odd = buffer[i + j + halfSize] * twiddle;
        buffer[i + j] = even + odd;
        buffer[i + j + halfSize] = even - odd;
      }
    }
  }
}
