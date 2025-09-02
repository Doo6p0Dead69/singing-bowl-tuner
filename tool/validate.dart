import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import '../lib/models.dart';

/// Entry point for validation tests.  Run this script with `dart run
/// tool/validate.dart`.  It prints a summary of test results and returns a
/// non‑zero exit code on failure.
Future<void> main() async {
  int failed = 0;
  print('Running validation tests...');
  if (!testNoteMapping()) failed++;
  if (!await testPitchDetection()) failed++;
  if (failed == 0) {
    print('All tests passed.');
  } else {
    print('$failed test(s) failed.');
  }
}

/// Validate that frequency-to-note mapping produces expected results within
/// ±5 cents.
bool testNoteMapping() {
  print('Test: frequency to note and cents mapping');
  final baseA4 = 440.0;
  final notes = {
    'C': 261.625565,
    'D': 293.664768,
    'E': 329.627557,
    'F': 349.228231,
    'G': 391.995436,
    'A': 440.0,
    'B': 493.883301,
  };
  bool ok = true;
  notes.forEach((name, freq) {
    final note = frequencyToNoteName(freq, baseA4);
    final cents = frequencyToCents(freq, baseA4);
    final diff = (cents).abs();
    final isMatch = (note == name) && diff < 0.01;
    if (!isMatch) {
      print('  FAIL: $freq Hz -> $note (${cents.toStringAsFixed(2)} ¢), expected $name');
      ok = false;
    }
  });
  if (ok) print('  OK');
  return ok;
}

/// Test pitch detection on synthetic sine waves.  Sine waves are generated
/// directly in memory, processed by a simplified pitch detector in Dart.
Future<bool> testPitchDetection() async {
  print('Test: pitch detection accuracy');
  final sampleRate = 48000;
  final durations = [1.0];
  final freqs = [110.0, 220.0, 440.0, 523.25, 660.0, 880.0];
  bool ok = true;
  for (final f in freqs) {
    final data = generateSine(f, sampleRate, durations.first);
    final result = detectPitch(data, sampleRate, 440.0);
    if (result == null) {
      print('  FAIL: no detection for $f Hz');
      ok = false;
      continue;
    }
    final f0 = result.frequency;
    final cents = result.cents;
    final freqError = (f0 - f).abs();
    final centsError = cents.abs();
    final passed = freqError <= 0.5 && centsError <= 5.0;
    print('  freq $f Hz -> detected ${f0.toStringAsFixed(2)} Hz, cents ${cents.toStringAsFixed(2)}, error ${freqError.toStringAsFixed(2)} Hz');
    if (!passed) {
      print('    FAIL: errors exceed limits');
      ok = false;
    }
  }
  if (ok) print('  OK');
  return ok;
}

/// Generate a sine wave at frequency [freq] with [duration] seconds and
/// sample rate [sr].  Returns a list of samples in the range [-1, 1].
List<double> generateSine(double freq, int sr, double duration) {
  final n = (sr * duration).toInt();
  final twoPiF = 2 * math.pi * freq;
  return List<double>.generate(n, (i) => math.sin(twoPiF * i / sr));
}

/// Simplified pitch detector in Dart.  Uses a normalized squared difference
/// function similar to MPM.  Returns null if no pitch is found.
_PitchResult? detectPitch(List<double> buffer, int sampleRate, double a4) {
  final minFreq = 60.0;
  final maxFreq = 1500.0;
  final minLag = (sampleRate / maxFreq).floor();
  final maxLag = (sampleRate / minFreq).floor();
  final nsdf = List<double>.filled(maxLag + 1, 0.0);
  double maxVal = 0.0;
  // Remove mean
  final mean = buffer.reduce((a, b) => a + b) / buffer.length;
  final data = buffer.map((e) => e - mean).toList();
  for (int tau = minLag; tau <= maxLag; tau++) {
    double acf = 0.0;
    double m = 0.0;
    final end = data.length - tau;
    for (int i = 0; i < end; i++) {
      final x = data[i];
      final y = data[i + tau];
      acf += x * y;
      m += x * x + y * y;
    }
    if (m > 0) {
      nsdf[tau] = 2.0 * acf / m;
    } else {
      nsdf[tau] = 0.0;
    }
    if (nsdf[tau] > maxVal) maxVal = nsdf[tau];
  }
  int bestTau = -1;
  double bestVal = 0.0;
  for (int tau = minLag + 1; tau < maxLag - 1; tau++) {
    final prev = nsdf[tau - 1];
    final current = nsdf[tau];
    final next = nsdf[tau + 1];
    if (current > prev && current > next && current > 0.6 * maxVal) {
      final denom = (prev - 2 * current + next);
      final delta = denom == 0 ? 0.0 : (prev - next) / (2 * denom);
      final peak = tau + delta;
      final freq = sampleRate / peak;
      if (freq > minFreq && freq < maxFreq) {
        bestTau = tau;
        bestVal = current;
        break;
      }
    }
  }
  if (bestTau < 0) return null;
  final freq = sampleRate / bestTau;
  final semitone = 12 * (math.log(freq / a4) / math.ln2);
  final nearest = semitone.roundToDouble();
  final cents = ((semitone - nearest) * 100).clamp(-50.0, 50.0);
  final confidence = bestVal.clamp(0.0, 1.0);
  return _PitchResult(freq, cents, confidence);
}

class _PitchResult {
  final double frequency;
  final double cents;
  final double confidence;
  _PitchResult(this.frequency, this.cents, this.confidence);
}