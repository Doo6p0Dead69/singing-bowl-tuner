import 'dart:math' as math;
import 'package:flutter/material.dart';

class TunerGauge extends StatelessWidget {
  final int cents; // -50..+50
  const TunerGauge({super.key, required this.cents});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: CustomPaint(
        painter: _GaugePainter(cents: cents),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int cents;
  _GaugePainter({required this.cents});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w/2, h*0.9);
    final radius = math.min(w/2-16, h*0.85);

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()..style=PaintingStyle.stroke..strokeWidth=8..color=Colors.grey.shade800;
    final tick = Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=Colors.grey.shade400;

    final start = math.pi*1.15, sweep = math.pi*0.7;
    canvas.drawArc(arcRect, start, sweep, false, base);

    for (int c=-50; c<=50; c+=10) {
      final a = _angleForCents(c, start, sweep);
      final p1 = _point(center, radius-8, a);
      final p2 = _point(center, radius-22, a);
      canvas.drawLine(p1, p2, tick);
    }
    final a0 = _angleForCents(0, start, sweep);
    canvas.drawLine(_point(center, radius, a0), _point(center, radius-28, a0), Paint()..strokeWidth=4..color=Colors.yellow);

    final clampC = cents.clamp(-50, 50);
    final a = _angleForCents(clampC, start, sweep);
    final p = _point(center, radius-36, a);
    final needle = Paint()..strokeWidth=6..color=Colors.orangeAccent..strokeCap=StrokeCap.round;
    canvas.drawLine(center, p, needle);
    canvas.drawCircle(center, 8, Paint()..color=Colors.orangeAccent);
  }

  double _angleForCents(int cents, double start, double sweep) {
    final t = (cents + 50) / 100.0;
    return start + sweep * t;
  }

  Offset _point(Offset c, double r, double angle) => Offset(c.dx + r*math.cos(angle), c.dy + r*math.sin(angle));

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.cents != cents;
}
