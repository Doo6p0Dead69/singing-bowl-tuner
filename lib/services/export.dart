import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/models.dart';

class Exporter {
  static Future<void> exportJson(List<BowlEntry> bowls) async {
    final list = bowls.map((b)=> {
      'name': b.name, 'frequencyHz': b.frequencyHz, 'note': b.note,
      'cents': b.cents, 'createdAt': b.createdAt.toIso8601String(), 'memo': b.memo
    }).toList();
    final text = const JsonEncoder.withIndent('  ').convert(list);
    await Share.share(text, subject: 'SingingBowlTuner.json');
  }

  static Future<void> exportCsv(List<BowlEntry> bowls) async {
    final buf = StringBuffer('name,frequencyHz,note,cents,createdAt,memo\n');
    for (final b in bowls) {
      buf.writeln('"${b.name.replaceAll('"','""')}",${b.frequencyHz.toStringAsFixed(4)},${b.note},${b.cents},"${b.createdAt.toIso8601String()}","${b.memo.replaceAll('"','""')}"');
    }
    await Share.share(buf.toString(), subject: 'SingingBowlTuner.csv');
  }

  static Future<List<BowlEntry>> importJsonOrCsv() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json','csv'], withData: true);
    if (res == null || res.files.isEmpty) return [];
    final bytes = res.files.single.bytes!;
    final text = utf8.decode(bytes);
    if ((res.files.single.extension ?? '').toLowerCase() == 'csv') return _parseCsv(text);
    return _parseJson(text);
  }

  static List<BowlEntry> _parseJson(String text) {
    final arr = json.decode(text) as List;
    return arr.map((e) => BowlEntry(
      name: e['name'] ?? '',
      frequencyHz: (e['frequencyHz'] as num).toDouble(),
      note: e['note'] ?? '',
      cents: (e['cents'] as num).toInt(),
      createdAt: DateTime.tryParse(e['createdAt'] ?? '') ?? DateTime.now(),
      memo: e['memo'] ?? '',
    )).toList();
  }

  static List<BowlEntry> _parseCsv(String text) {
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty) return [];
    final out = <BowlEntry>[];
    for (var i=1;i<lines.length;i++){
      final raw = _splitCsv(lines[i]);
      if (raw.length < 6) continue;
      out.add(BowlEntry(
        name: raw[0],
        frequencyHz: double.tryParse(raw[1]) ?? 0,
        note: raw[2],
        cents: int.tryParse(raw[3]) ?? 0,
        createdAt: DateTime.tryParse(raw[4]) ?? DateTime.now(),
        memo: raw[5],
      ));
    }
    return out;
  }

  static List<String> _splitCsv(String line) {
    final r = <String>[];
    final sb = StringBuffer();
    bool inQ=false;
    for (int i=0;i<line.length;i++) {
      final c = line[i];
      if (c=='"'){
        if (inQ && i+1<line.length && line[i+1]=='"') { sb.write('"'); i+=1; }
        else { inQ = !inQ; }
      } else if (c==',' && !inQ) {
        r.add(sb.toString()); sb.clear();
      } else {
        sb.write(c);
      }
    }
    r.add(sb.toString());
    return r;
  }
}
