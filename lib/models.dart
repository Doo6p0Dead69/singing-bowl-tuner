import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class representing a single measurement for a singing bowl.
class Measurement {
  Measurement({
    required this.note,
    required this.frequency,
    required this.cents,
    required this.dateTime,
    this.bowlName,
    this.comment,
  });

  final String note;
  final double frequency;
  final double cents;
  final DateTime dateTime;
  final String? bowlName;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'note': note,
        'frequency': frequency,
        'cents': cents,
        'dateTime': dateTime.toIso8601String(),
        'bowlName': bowlName,
        'comment': comment,
      };

  static Measurement fromJson(Map<String, dynamic> json) => Measurement(
        note: json['note'] as String,
        frequency: (json['frequency'] as num).toDouble(),
        cents: (json['cents'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime'] as String),
        bowlName: json['bowlName'] as String?,
        comment: json['comment'] as String?,
      );
}

/// Application state containing current configuration and measurement history.
class AppState extends ChangeNotifier {
  double a4 = 440.0;
  String locale = 'ru';
  bool autoStart = false;
  bool noiseGate = true;
  double sampleRate = 48000.0;
  final List<Measurement> measurements = [];

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    a4 = prefs.getDouble('a4') ?? 440.0;
    locale = prefs.getString('locale') ?? 'ru';
    autoStart = prefs.getBool('autoStart') ?? false;
    noiseGate = prefs.getBool('noiseGate') ?? true;
    sampleRate = prefs.getDouble('sampleRate') ?? 48000.0;
    final data = prefs.getStringList('measurements') ?? [];
    measurements
      ..clear()
      ..addAll(data.map((e) => Measurement.fromJson(
          Map<String, dynamic>.from(Uri.decodeFull(e).toMap()))));
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('a4', a4);
    await prefs.setString('locale', locale);
    await prefs.setBool('autoStart', autoStart);
    await prefs.setBool('noiseGate', noiseGate);
    await prefs.setDouble('sampleRate', sampleRate);
    final list = measurements
        .map((m) => Uri.encodeFull(m.toJson().toString()))
        .toList();
    await prefs.setStringList('measurements', list);
  }

  /// Add a new measurement and persist it.
  Future<void> addMeasurement(Measurement measurement) async {
    measurements.add(measurement);
    await savePreferences();
    notifyListeners();
  }

  /// Remove a measurement at the given index.
  Future<void> removeMeasurement(int index) async {
    measurements.removeAt(index);
    await savePreferences();
    notifyListeners();
  }

  /// Change the language.
  Future<void> setLocale(String lang) async {
    locale = lang;
    await savePreferences();
    notifyListeners();
  }

  /// Export data to CSV string.
  String exportCsv() {
    final buffer = StringBuffer();
    buffer.writeln('dateTime,note,frequency,cents,bowlName,comment');
    for (final m in measurements) {
      buffer.writeln(
          '${m.dateTime.toIso8601String()},${m.note},${m.frequency.toStringAsFixed(2)},${m.cents.toStringAsFixed(2)},${m.bowlName ?? ''},${m.comment ?? ''}');
    }
    return buffer.toString();
  }

  /// Export data to JSON string.
  String exportJson() {
    final list = measurements.map((m) => m.toJson()).toList();
    return list.toString();
  }
}

/// Convert frequency [f0] to the nearest note name (C, C#, ..., B) based on
/// reference A4.  Returns only the note letter without octave.
String frequencyToNoteName(double f0, double a4) {
  // Calculate semitone distance from A4.
  final semitone = 12 * math.log(f0 / a4) / math.ln2;
  int noteIndex = (semitone.round() + 9) % 12; // A is index 9 relative to C
  if (noteIndex < 0) noteIndex += 12;
  return _noteNames[noteIndex];
}

/// Compute deviation in cents between [f0] and the nearest equal tempered pitch
/// relative to A4 tuning.  The returned value ranges from -50 to +50 when
/// [frequencyToNoteName] is used to find the nearest note.
double frequencyToCents(double f0, double a4) {
  final semitone = 12 * math.log(f0 / a4) / math.ln2;
  final nearest = semitone.roundToDouble();
  final diff = (semitone - nearest) * 100.0;
  return diff.clamp(-50.0, 50.0);
}

/// List of note names used throughout the app.
const List<String> _noteNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Extension to convert a string representing a map (produced by [toString])
/// back into a Map.  This is a workaround because SharedPreferences does not
/// support storing arbitrary JSON objects.  Keys and values must not contain
/// commas or braces.
extension _MapParsing on String {
  Map<String, dynamic> toMap() {
    final trimmed = substring(1, length - 1); // remove { }
    final entries = trimmed.split(',');
    final map = <String, dynamic>{};
    for (final entry in entries) {
      final kv = entry.split(':');
      if (kv.length >= 2) {
        final key = kv.first.trim();
        final value = kv.sublist(1).join(':').trim();
        map[key] = value;
      }
    }
    return map;
  }
}