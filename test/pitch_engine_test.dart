import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:singing_bowl_tuner/domain/pitch_engine.dart';

void main() {
  test('sine 440Hz detected ~440', () async {
    final cfg = PitchConfig(
      sampleRate: 48000, fftSize: 4096, hopSize: 1024,
      minHz: 60, maxHz: 1200, focusMinHz: 80, focusMaxHz: 600,
      sensitivity: 1, stableMs: 300, a4: 440,
    );
    final eng = PitchEngine();
    await eng.start(cfg);
    final f = 440.0;
    final n = 1024;
    final block = Float32List(n);
    for (int i=0;i<n;i++){ block[i] = math.sin(2*math.pi*f*i/cfg.sampleRate).toDouble(); }
    eng.pushAudio(block);
    final res = await eng.stream.firstWhere((r)=> r.ok);
    expect((res.frequencyHz-440).abs() < 2.0, true);
    await eng.stop();
  });
}
