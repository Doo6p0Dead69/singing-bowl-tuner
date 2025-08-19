import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'dsp/fft.dart';
import 'dsp/window.dart';
import 'dsp/aweighting.dart';
import 'dsp/hps.dart';
import 'dsp/smoothing.dart';

class PitchResult {
  final double frequencyHz;
  final bool ok;
  final double snrDb;
  final double quality; // 0..1
  final int hopMs;
  PitchResult(this.frequencyHz, this.ok, this.snrDb, this.quality, this.hopMs);
}

class PitchConfig {
  final int sampleRate;
  final int fftSize; // 4096
  final int hopSize; // 1024
  final double minHz; // 60
  final double maxHz; // 1200
  final double focusMinHz; // 80
  final double focusMaxHz; // 600
  final double sensitivity; // 0..1
  final int stableMs; // 300..500
  final double a4;
  PitchConfig({
    required this.sampleRate, required this.fftSize, required this.hopSize,
    required this.minHz, required this.maxHz, required this.focusMinHz, required this.focusMaxHz,
    required this.sensitivity, required this.stableMs, required this.a4
  });

  Map<String, dynamic> toMap() => {
    'sampleRate': sampleRate, 'fftSize': fftSize, 'hopSize': hopSize,
    'minHz': minHz, 'maxHz': maxHz, 'focusMinHz': focusMinHz, 'focusMaxHz': focusMaxHz,
    'sensitivity': sensitivity, 'stableMs': stableMs, 'a4': a4,
  };
}

class PitchEngine {
  final _ctrl = StreamController<PitchResult>.broadcast();
  Stream<PitchResult> get stream => _ctrl.stream;

  SendPort? _send;
  ReceivePort? _recv;
  Isolate? _iso;

  Future<void> start(PitchConfig cfg) async {
    _recv = ReceivePort();
    _iso = await Isolate.spawn(_isoMain, _recv!.sendPort);
    _send = await _recv!.first as SendPort;
    _recv!.listen((msg) {
      if (msg is List && msg.length == 5) {
        _ctrl.add(PitchResult(msg[0] as double, msg[1] as bool, msg[2] as double, msg[3] as double, msg[4] as int));
      }
    });
    _send!.send(cfg.toMap());
  }

  void pushAudio(Float32List block){ _send?.send(block); }

  Future<void> stop() async {
    _send?.send(null);
    _recv?.close();
    _iso?.kill(priority: Isolate.immediate);
    await _ctrl.close();
  }

  static void _isoMain(SendPort mainPort) {
    final port = ReceivePort();
    mainPort.send(port.sendPort);

    late Map<String,dynamic> cfg;
    List<double>? window;
    FFT? fft;
    List<double>? fftRe, fftIm;
    late AWeighting aw;
    double noiseRms = 1e-6;

    final smoothing = MedianEMA(windowMs: 400, alpha: 0.2, sampleHopMs: 21);

    port.listen((msg) {
      if (msg is Map) {
        cfg = msg;
        window = blackmanHarris(cfg['fftSize'] as int);
        fft = FFT(cfg['fftSize'] as int);
        fftRe = List<double>.filled(cfg['fftSize'] as int, 0);
        fftIm = List<double>.filled(cfg['fftSize'] as int, 0);
        aw = AWeighting(cfg['sampleRate'] as int);
        return;
      }
      if (msg == null) { return; }
      if (msg is Float32List) {
        final hopSize = cfg['hopSize'] as int;
        final sampleRate = cfg['sampleRate'] as int;
        final hopMs = (1000.0 * hopSize / sampleRate).round();

        final block = msg;
        final rmsA = aw.processRms(block.toList());
        final snrOpen = 20 * math.log(rmsA / (noiseRms + 1e-12)) / math.ln10;
        final snrThreshold = 6 + (1 - (cfg['sensitivity'] as double)) * 8;
        final gateOpen = snrOpen >= snrThreshold;
        final beta = gateOpen ? 0.05 : 0.5;
        noiseRms = (1 - beta) * noiseRms + beta * rmsA;

        if (!gateOpen) {
          mainPort.send([double.nan, false, snrOpen, 0.0, hopMs]);
          return;
        }

        final N = cfg['fftSize'] as int;
        final re = fftRe!; final im = fftIm!;
        for (int i = 0; i < N; i++) {
          final s = (i < block.length) ? block[i].toDouble() : 0.0;
          final w = window![i];
          re[i] = s * w;
          im[i] = 0.0;
        }
        fft!.fft(re, im);

        final n2 = N ~/ 2;
        final mag = List<double>.filled(n2, 0);
        for (int k = 0; k < n2; k++) {
          final r = re[k], ii = im[k];
          mag[k] = math.sqrt(r*r + ii*ii) + 1e-12;
        }

        final hps = List<double>.from(mag);
        for (int factor=2; factor<=4; factor++) {
          for (int i=0; i<n2~/factor; i++) {
            hps[i] *= mag[i*factor];
          }
        }

        double bin2hz(int k) => k * (sampleRate / N);
        int hz2bin(double hz) => (hz * N / sampleRate).round();
        final kMin = hz2bin(cfg['minHz'] as double).clamp(1, n2-2);
        final kMax = hz2bin(cfg['maxHz'] as double).clamp(kMin+2, n2-1);

        int kPeak = kMin; double vPeak=-1e12;
        for (int k=kMin+1;k<kMax-1;k++){ final v=hps[k]; if (v>vPeak){ vPeak=v; kPeak=k; } }
        double parabolic(int k){
          final yl=hps[k-1], y0=hps[k], yr=hps[k+1];
          final d = (yl-2*y0+yr).abs()<1e-12 ? 0 : 0.5*(yl-yr)/(yl-2*y0+yr);
          return k + d;
        }
        final kInterp = kPeak.clamp(kMin+1, kMax-2);
        final kh = parabolic(kInterp);
        final fHps = bin2hz(kh.round()) + (kh - kh.floor()) * (sampleRate / N);

        for (int i=0;i<N;i++){ final r=re[i], ii=im[i]; re[i]=r*r+ii*ii; im[i]=0; }
        fft!.ifft(re, im);
        final r0 = re[0].abs() + 1e-12;
        final minLag=(sampleRate/(cfg['maxHz'] as double)).floor();
        final maxLag=(sampleRate/(cfg['minHz'] as double)).ceil().clamp(minLag+2, N-1);
        int tau=minLag; double best=-1e9;
        for (int t=minLag;t<=maxLag;t++){ final r=re[t]/r0; if (r>best){ best=r; tau=t; } }
        final fAcf = sampleRate / tau.toDouble();

        final start = hz2bin(cfg['focusMinHz'] as double).clamp(1, n2-1);
        final end = hz2bin(cfg['focusMaxHz'] as double).clamp(start+1, n2);
        final slice = (hps.sublist(start, end)..sort());
        final median = slice[slice.length~/2] + 1e-12;
        final snrDb = 10 * (math.log(vPeak/median)/math.ln10);
        final snrOk = snrDb > (10 + (1 - (cfg['sensitivity'] as double))*6);

        final diff = (fHps - fAcf).abs() / fHps;
        final quality = (0.5 * best.clamp(0, 1) + 0.5 * (1 - diff)).clamp(0.0, 1.0);
        final ok = snrOk && quality > 0.6;

        double fEst = fHps;
        fEst = smoothing.push(fEst);

        if (!ok || fEst.isNaN) {
          mainPort.send([double.nan, false, snrDb, quality, hopMs]);
          return;
        }
        mainPort.send([fEst, true, snrDb, quality, hopMs]);
      }
    });
  }
}
