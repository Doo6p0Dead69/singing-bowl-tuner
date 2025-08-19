import 'dart:collection';

class MedianEMA {
  final int windowMs;
  final double alpha;
  final int sampleHopMs;

  final Queue<double> _q = Queue();
  double? _ema;
  int _accMs = 0;

  MedianEMA({required this.windowMs, required this.alpha, required this.sampleHopMs});

  double push(double v) {
    _q.addLast(v);
    _accMs += sampleHopMs;
    while (_accMs > windowMs && _q.isNotEmpty) {
      _q.removeFirst();
      _accMs -= sampleHopMs;
    }
    final median = _median(_q);
    _ema = _ema == null ? median : alpha * median + (1 - alpha) * _ema!;
    return _ema!;
  }

  static double _median(Queue<double> q) {
    if (q.isEmpty) return double.nan;
    final list = q.toList()..sort();
    final m = list.length ~/ 2;
    return (list.length % 2 == 1) ? list[m] : (list[m-1] + list[m]) / 2;
  }
}
