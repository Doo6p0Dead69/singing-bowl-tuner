import 'package:flutter/material.dart';
import '../../services/localization.dart';

class QualityChip extends StatelessWidget {
  final bool ok;
  final double quality;
  const QualityChip({super.key, required this.ok, required this.quality});

  @override
  Widget build(BuildContext context) {
    final t = AppLoc.of(context);
    final text = ok ? t.ok : t.unsure;
    final color = ok ? Colors.green : Colors.amber;
    return Chip(
      label: Text('$text (${(quality*100).round()}%)'),
      backgroundColor: color.withOpacity(0.2),
      side: BorderSide(color: color),
    );
  }
}
