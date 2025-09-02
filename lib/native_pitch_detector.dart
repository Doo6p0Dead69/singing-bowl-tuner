import 'dart:async';
import 'package:flutter/services.dart';
import 'models.dart';

/// Data class representing pitch detection output from native code.
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

/// Wrapper around platform channels to communicate with native pitch detector
/// implementations.  Provides methods to start/stop audio capture and a
/// stream of [PitchResult] updates.
class NativePitchDetector {
  static final NativePitchDetector _instance = NativePitchDetector._internal();

  factory NativePitchDetector() => _instance;

  NativePitchDetector._internal() {
    _eventChannel.receiveBroadcastStream().listen(_onEvent);
  }

  static const MethodChannel _methodChannel =
      MethodChannel('singing_bowl_tuner/method');
  static const EventChannel _eventChannel =
      EventChannel('singing_bowl_tuner/events');

  final StreamController<PitchResult> _controller =
      StreamController<PitchResult>.broadcast();

  /// Stream of pitch updates.  Listeners should cancel subscriptions when
  /// done to avoid memory leaks.
  Stream<PitchResult> get results => _controller.stream;

  Future<void> start(double a4, double sampleRate, bool noiseGate) async {
    await _methodChannel.invokeMethod('start', {
      'a4': a4,
      'sampleRate': sampleRate,
      'noiseGate': noiseGate,
    });
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod('stop');
  }

  void _onEvent(dynamic event) {
    if (event is Map) {
      final freq = (event['frequency'] as num).toDouble();
      final cents = (event['cents'] as num).toDouble();
      final conf = (event['confidence'] as num).toDouble();
      final over = (event['overtones'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [];
      final res = PitchResult(
        frequency: freq,
        cents: cents,
        confidence: conf,
        overtones: over,
      );
      _controller.add(res);
    }
  }
}