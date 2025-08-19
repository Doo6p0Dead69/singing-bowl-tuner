import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:singing_bowl_tuner/presentation/widgets/gauge.dart';

void main() {
  testWidgets('Gauge paints', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: TunerGauge(cents: 13))));
    expect(find.byType(TunerGauge), findsOneWidget);
  });
}
