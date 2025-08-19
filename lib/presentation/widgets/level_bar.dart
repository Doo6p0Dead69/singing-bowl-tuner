import 'package:flutter/material.dart';

class LevelBar extends StatelessWidget {
  final double snrDb; // -inf..+inf
  const LevelBar({super.key, required this.snrDb});

  @override
  Widget build(BuildContext context) {
    final t = snrDb.isFinite ? ((snrDb+10)/30.0).clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: t,
          color: t>0.8? Colors.green: (t>0.5? Colors.orange: Colors.red),
          backgroundColor: Colors.grey.shade900,
        ),
      ),
    );
  }
}
