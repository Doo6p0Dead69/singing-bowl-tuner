import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../services/audio_stream.dart';
import '../../services/localization.dart';
import '../../services/preferences.dart';
import '../../data/repository.dart';
import '../../data/models.dart';
import '../../domain/pitch_engine.dart';
import '../../domain/note_mapper.dart';
import '../widgets/gauge.dart';
import '../widgets/level_bar.dart';
import '../widgets/quality_chip.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});
  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final audio = AudioStreamService();
  final engine = PitchEngine();
  StreamSubscription? _audioSub;
  double _freq = double.nan;
  bool _ok = false;
  double _snrDb = 0;
  double _quality = 0;
  int _hopMs = 21;
  late NoteMapper _nm;
  late Preferences _prefs;

  int _cents = 0;
  String _note = '--';

  Timer? _stableTimer;
  bool _stable = false;

  @override
  void initState() {
    super.initState();
    _prefs = Preferences.instance;
    _nm = NoteMapper(_prefs.a4);
    _boot();
  }

  Future<void> _boot() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Разрешите доступ к микрофону')));
      }
      return;
    }
    await engine.start(PitchConfig(
      sampleRate: 48000, fftSize: 4096, hopSize: 1024,
      minHz: _prefs.minHz, maxHz: _prefs.maxHz,
      focusMinHz: _prefs.focusMinHz, focusMaxHz: _prefs.focusMaxHz,
      sensitivity: _prefs.sensitivity, stableMs: _prefs.stableMs, a4: _prefs.a4,
    ));
    final stream = audio.start(sampleRate: 48000, bufferSize: 1024);
    _audioSub = stream.listen((Float32List block) {
      engine.pushAudio(block);
    });
    engine.stream.listen((res) {
      setState(() {
        _hopMs = res.hopMs;
        _snrDb = res.snrDb;
        _quality = res.quality;
      });
      if (res.ok && res.frequencyHz.isFinite) {
        final f = res.frequencyHz;
        final midi = _nm.midiFromFreq(f);
        final fNote = _nm.nearestNoteFreq(f);
        final cents = _nm.cents(f, fNote);
        _scheduleStability(res.ok, _prefs.stableMs);
        if (!_prefs.stableOnly || _stable) {
          setState(() {
            _freq = f;
            _note = _nm.nameWithOctave(midi);
            _cents = cents.clamp(-50, 50);
            _ok = true;
          });
        }
      } else {
        setState(() { _ok = false; });
      }
    });
  }

  void _scheduleStability(bool ok, int ms) {
    _stableTimer?.cancel();
    if (!ok) { _stable = false; return; }
    _stableTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() { _stable = true; });
    });
  }

  @override
  void dispose() {
    _stableTimer?.cancel();
    _audioSub?.cancel();
    engine.stop();
    audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLoc.of(context);
    final decimals = _prefs.decimals;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          TunerGauge(cents: _cents),
          const SizedBox(height: 12),
          Text(_note, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(_freq.isFinite ? '${_freq.toStringAsFixed(decimals)} ${t.hz}' : '--', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              QualityChip(ok: _ok, quality: _quality),
              const SizedBox(width: 12),
              Text('${t.a4Equals} ${_prefs.a4.toStringAsFixed(1)} ${t.hz}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.signal),
                LevelBar(snrDb: _snrDb),
              ],
            )),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(t.capture),
              onPressed: _ok ? _capture : null,
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.tune),
                label: Text('${t.filterRange} ${_prefs.minHz.toInt()}–${_prefs.maxHz.toInt()} ${t.hz}'),
                onPressed: _changeRange,
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.center_focus_strong),
                label: Text('${t.focusRange} ${_prefs.focusMinHz.toInt()}–${_prefs.focusMaxHz.toInt()} ${t.hz}'),
                onPressed: _changeFocus,
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch(value: _prefs.stableOnly, onChanged: (v) => _prefs.stableOnly = v),
              Text(t.stableOnly),
              const Spacer(),
              Text('${t.trackingQuality}: ${(_quality*100).round()}%'),
            ],
          ),
          if (!_ok) Padding(
            padding: const EdgeInsets.only(top:12),
            child: Text(AppLoc.of(context).snrTooLow, style: TextStyle(color: Colors.amber.shade300)),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Future<void> _capture() async {
    final repo = context.read<Repository>();
    final t = AppLoc.of(context);
    final controller = TextEditingController(text: _note);
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(t.capture),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: t.name)),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text(t.cancel)),
          ElevatedButton(onPressed: (){
            final b = BowlEntry(
              name: controller.text,
              frequencyHz: _freq,
              note: _note,
              cents: _cents,
              createdAt: DateTime.now(),
              memo: '',
            );
            repo.addBowl(b);
            Navigator.pop(ctx);
          }, child: Text(t.save))
        ],
      );
    });
  }

  Future<void> _changeRange() async {
    await _rangeDialog(min: true);
  }
  Future<void> _changeFocus() async {
    await _rangeDialog(min: false);
  }

  Future<void> _rangeDialog({required bool min}) async {
    final t = AppLoc.of(context);
    final minVal = min ? _prefs.minHz : _prefs.focusMinHz;
    final maxVal = min ? _prefs.maxHz : _prefs.focusMaxHz;
    final ctrlMin = TextEditingController(text: minVal.toStringAsFixed(0));
    final ctrlMax = TextEditingController(text: maxVal.toStringAsFixed(0));
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(min ? t.filterRange : t.focusRange),
        content: Row(children: [
          Expanded(child: TextField(controller: ctrlMin, keyboardType: TextInputType.number)),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: ctrlMax, keyboardType: TextInputType.number)),
        ]),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text(t.cancel)),
          ElevatedButton(onPressed: (){
            final a = double.tryParse(ctrlMin.text) ?? minVal;
            final b = double.tryParse(ctrlMax.text) ?? maxVal;
            if (min) { _prefs.minHz = a; _prefs.maxHz = b; }
            else { _prefs.focusMinHz = a; _prefs.focusMaxHz = b; }
            Navigator.pop(ctx);
          }, child: Text(t.save)),
        ],
      );
    });
  }
}
