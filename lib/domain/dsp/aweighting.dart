import 'dart:math' as math;

class AWeighting {
  late final _Biquad _bq;
  AWeighting(int fs) {
    if (fs >= 47000) {
      _bq = _Biquad(
        b0: 0.23430179, b1: -0.46860358, b2: 0.23430179,
        a1: -1.76004188, a2: 0.80291978,
      );
    } else {
      _bq = _Biquad(
        b0: 0.25574113, b1: -0.51148227, b2: 0.25574113,
        a1: -1.80734060, a2: 0.82470695,
      );
    }
  }
  double processRms(List<double> x) {
    double s = 0;
    for (final v in x) {
      final y = _bq.process(v);
      s += y*y;
    }
    return math.sqrt(s / x.length);
  }
}

class _Biquad {
  final double b0, b1, b2, a1, a2;
  double z1=0, z2=0;
  _Biquad({required this.b0, required this.b1, required this.b2, required this.a1, required this.a2});
  double process(double x) {
    final y = b0*x + z1;
    z1 = b1*x - a1*y + z2;
    z2 = b2*x - a2*y;
    return y;
  }
}
