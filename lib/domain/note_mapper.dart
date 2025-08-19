import 'dart:math' as math;

class NoteMapper {
  final double a4;
  NoteMapper(this.a4);

  static const _names = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];

  double freqFromMidi(int midi) => a4 * math.pow(2, (midi - 69) / 12.0);
  int midiFromFreq(double f) => (69 + 12 * (math.log(f / a4) / math.ln2)).round();
  double nearestNoteFreq(double f) => freqFromMidi(midiFromFreq(f));

  String nameWithOctave(int midi) {
    final name = _names[midi % 12];
    final octave = (midi ~/ 12) - 1;
    return '$name$octave';
  }

  int cents(double f, double fNote) => (1200 * (math.log(f / fNote) / math.ln2)).round();
}
