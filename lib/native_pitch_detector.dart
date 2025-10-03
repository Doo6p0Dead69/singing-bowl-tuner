import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dsp/fft.dart';
import 'models.dart';

/// Data class representing pitch detection output from digital signal
/// processing in Dart code.
class PitchResult {
  PitchResult({
    required this.frequency,
    required this.cents,
    required this.confidence,
    required this.overtones,
  });

  final double frequency;
  final double cents;
  final double confidence;
  final List<double> overtones;

  String get note => frequencyToNoteName(frequency, 440.0);
}

/// Real-time pitch detector implemented in pure Dart.  Audio samples are
/// captured via `flutter_audio_capture`, transformed with an FFT, and analysed
/// to estimate the fundamental frequency while ignoring overtones and noise.
class NativePitchDetector {
  static final NativePitchDetector _instance = NativePitchDetector._internal();

  factory NativePitchDetector() => _instance;

  NativePitchDetector._internal();

  final FlutterAudioCapture _capture = FlutterAudioCapture();
  final StreamController<PitchResult> _controller =
      StreamController<PitchResult>.broadcast();
  final List<double> _buffer = <double>[];

  bool _running = false;
  double _a4 = 440.0;
  double _sampleRate = 48000.0;
  bool _noiseGate = true;

  static const int _windowSize = 4096;
  static const int _hopSize = 2048;

  /// Stream of pitch updates produced by the detector.
  Stream<PitchResult> get results => _controller.stream;

  Future<void> start(double a4, double sampleRate, bool noiseGate) async {
    if (_running) {
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _controller.addError('Microphone permission denied');
      return;
    }

    _a4 = a4;
    _sampleRate = sampleRate;
    _noiseGate = noiseGate;
    _running = true;
    _buffer.clear();

    try {
      await _capture.start(
        listener: _onAudioSample,
        sampleRate: sampleRate.toInt(),
        bufferSize: _windowSize,
      );
    } catch (error) {
      _controller.addError('Failed to start audio capture: $error');
      _running = false;
    }
  }

  Future<void> stop() async {
    if (!_running) {
      return;
    }
    try {
      await _capture.stop();
    } catch (_) {
      // Ignored – stopping may throw if capture was not fully started.
    }
    _running = false;
    _buffer.clear();
  }

  void _onAudioSample(dynamic event) {
    final samples = _convertToDouble(event);
    if (samples.isEmpty) {
      return;
    }
    _buffer.addAll(samples);

    while (_buffer.length >= _windowSize) {
      final frame = List<double>.from(_buffer.getRange(0, _windowSize));
      _buffer.removeRange(0, _hopSize);
      final result = _analyseFrame(frame);
      if (result != null) {
        _controller.add(result);
      }
    }
  }

  List<double> _convertToDouble(dynamic event) {
    if (event is Float64List) {
      return event.toList();
    }
    if (event is Float32List) {
      return event.map((e) => e.toDouble()).toList();
    }
    if (event is Int16List) {
      return event.map((e) => e.toDouble() / 32768.0).toList();
    }
    if (event is Uint8List) {
      // Convert little-endian 16-bit PCM stored in a byte buffer.
      final int16 = Int16List.view(event.buffer);
      return int16.map((e) => e.toDouble() / 32768.0).toList();
    }
    if (event is List) {
      return event.map((e) => (e as num).toDouble()).toList();
    }
    return const [];
  }

  PitchResult? _analyseFrame(List<double> frame) {
    if (frame.every((sample) => sample == 0.0)) {
      return null;
    }

    final windowed = _applyHannWindow(frame);
    final spectrum = fftReal(windowed);
    final half = spectrum.length ~/ 2;
    final magnitudes = List<double>.generate(half, (i) => spectrum[i].magnitude);

    final energy = magnitudes.fold<double>(0, (acc, v) => acc + v * v) / half;
    final rms = math.sqrt(energy);
    if (_noiseGate && rms < 0.005) {
      return null;
    }

    final peaks = _findSpectralPeaks(magnitudes);
    if (peaks.isEmpty) {
      return null;
    }

    final scored = peaks
        .map((peak) => _scorePeak(peak, peaks))
        .where((peak) => peak.score > 0)
        .toList();
    if (scored.isEmpty) {
      return null;
    }

    scored.sort((a, b) {
      final diff = b.score.compareTo(a.score);
      if (diff != 0) return diff;
      return a.frequency.compareTo(b.frequency);
    });

    final fundamental = scored.first;
    final cents = frequencyToCents(fundamental.frequency, _a4);
    final totalScore =
        scored.fold<double>(0, (acc, item) => acc + item.score).abs();
    final confidence = totalScore == 0
        ? 0.0
        : (fundamental.score / totalScore).clamp(0.0, 1.0);

    final overtoneFrequencies = scored
        .skip(1)
        .toList()
      ..sort((a, b) => a.frequency.compareTo(b.frequency));

    final overtoneList = overtoneFrequencies
        .take(6)
        .map((peak) => peak.frequency)
        .toList();

    return PitchResult(
      frequency: fundamental.frequency,
      cents: cents,
      confidence: confidence,
      overtones: overtoneList,
    );
  }

  List<double> _applyHannWindow(List<double> samples) {
    final n = samples.length;
    return List<double>.generate(
      n,
      (i) => samples[i] * (0.5 - 0.5 * math.cos((2 * math.pi * i) / (n - 1))),
    );
  }

  List<_Peak> _findSpectralPeaks(List<double> magnitudes) {
    final result = <_Peak>[];
    final nyquist = _sampleRate / 2.0;
    for (var i = 2; i < magnitudes.length - 2; i++) {
      final mag = magnitudes[i];
      if (mag <= magnitudes[i - 1] || mag <= magnitudes[i + 1]) {
        continue;
      }
      final freq = (i * nyquist) / magnitudes.length;
      if (freq < 40 || freq > 2500) {
        continue;
      }
      result.add(_Peak(frequency: freq, amplitude: mag));
    }

    if (result.isEmpty) {
      return result;
    }

    final amplitudes = result.map((e) => e.amplitude).toList();
    final mean = amplitudes.reduce((a, b) => a + b) / amplitudes.length;
    final variance = amplitudes
            .map((a) => (a - mean) * (a - mean))
            .reduce((a, b) => a + b) /
        amplitudes.length;
    final std = math.sqrt(variance);
    final threshold = math.max(mean + std, mean * 1.25);
    final filtered =
        result.where((peak) => peak.amplitude >= threshold).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    result.sort((a, b) => b.amplitude.compareTo(a.amplitude));
    return result.take(6).toList();
  }

  _ScoredPeak _scorePeak(_Peak candidate, List<_Peak> allPeaks) {
    double score = candidate.amplitude;
    for (final peak in allPeaks) {
      if (identical(peak, candidate)) {
        continue;
      }
      final ratio = peak.frequency / candidate.frequency;
      if (ratio < 1.8) {
        continue;
      }
      final harmonic = ratio.round();
      if (harmonic < 2 || (ratio - harmonic).abs() > 0.08 * harmonic) {
        continue;
      }
      score += peak.amplitude / harmonic;
    }
    return _ScoredPeak(
      frequency: candidate.frequency,
      amplitude: candidate.amplitude,
      score: score,
    );
  }
}

class _Peak {
  _Peak({required this.frequency, required this.amplitude});

  final double frequency;
  final double amplitude;
}

class _ScoredPeak extends _Peak {
  _ScoredPeak({
    required super.frequency,
    required super.amplitude,
    required this.score,
  });

  final double score;
}
