import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class AudioStreamService {
  static const _event = EventChannel('audio_stream/events');
  static const _method = MethodChannel('audio_stream/methods');

  Stream<Float32List>? _stream;

  Stream<Float32List> start({int sampleRate = 48000, int bufferSize = 1024}) {
    _method.invokeMethod('start', {'sampleRate': sampleRate, 'bufferSize': bufferSize});
    _stream ??= _event.receiveBroadcastStream().map((e) => (e as Float32List));
    return _stream!;
  }

  Future<void> stop() async {
    await _method.invokeMethod('stop');
  }
}
