import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../data/models.dart';
import '../../services/localization.dart';
import '../../services/export.dart';

class SetBuilderScreen extends StatefulWidget {
  const SetBuilderScreen({super.key});
  @override
  State<SetBuilderScreen> createState() => _SetBuilderScreenState();
}

class _SetBuilderScreenState extends State<SetBuilderScreen> {
  bool byNotes = true;
  int tolerance = 15; // cents
  final List<String> targetOrder = const ['C','D','E','F','G','A','B'];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repository>();
    final t = AppLoc.of(context);
    final bowls = repo.getAllBowls().toList()..sort((a,b)=> a.frequencyHz.compareTo(b.frequencyHz));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.setOf7),
        actions: [
          IconButton(icon: const Icon(Icons.save_alt), onPressed: () async {
            final ids = _selectBest(bowls);
            final set = BowlSet(title: byNotes ? 'By Notes' : 'By Frequency', bowlIds: ids, createdAt: DateTime.now());
            await repo.addSet(set);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
          }),
          IconButton(icon: const Icon(Icons.share), onPressed: () async {
            final ids = _selectBest(bowls);
            final selected = ids.map((i)=> bowls[i]).toList();
            await Exporter.exportCsv(selected);
          }),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(byNotes ? t.modeByNotes : t.modeByFreq),
            value: byNotes, onChanged: (v)=> setState(()=> byNotes = v),
          ),
          ListTile(
            title: Text('${t.tolerance}: ±$tolerance ${t.centsShort}'),
            subtitle: const Text('Adjust acceptance window per position'),
            trailing: SizedBox(width:160, child: Slider(min:5, max:30, divisions:5, value: tolerance.toDouble(), onChanged: (v)=> setState(()=> tolerance = v.round()))),
          ),
          const Divider(),
          Expanded(child: byNotes
            ? _buildByNotes(bowls, tolerance)
            : _buildByFreq(bowls, tolerance))
        ],
      ),
    );
  }

  Widget _buildByNotes(List<BowlEntry> bowls, int tol) {
    final t = AppLoc.of(context);
    final rows = <Widget>[];
    for (final name in targetOrder) {
      final candidates = bowls.where((b) => b.note.startsWith(name)).toList()
        ..sort((a,b)=> a.cents.abs().compareTo(b.cents.abs()));
      final choice = candidates.where((b)=> b.cents.abs() <= tol).toList();
      if (choice.isNotEmpty) {
        final b = choice.first;
        rows.add(ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text('$name — ${b.name}'),
          subtitle: Text('${b.note} • ${b.frequencyHz.toStringAsFixed(2)} Hz • ${(b.cents>=0?'+':'')}${b.cents} ${t.centsShort}'),
        ));
      } else {
        rows.add(ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.amber),
          title: Text('$name — ${t.missingBowl} …'),
          subtitle: const Text('Try capture more bowls or widen tolerance'),
        ));
      }
    }
    return ListView(children: rows);
  }

  Widget _buildByFreq(List<BowlEntry> bowls, int tol) {
    final t = AppLoc.of(context);
    final sorted = bowls.toList()
      ..sort((a,b)=> a.frequencyHz.compareTo(b.frequencyHz));
    final chosen = <BowlEntry>[];
    for (final b in sorted) {
      if (chosen.length==7) break;
      if (b.cents.abs() <= tol) chosen.add(b);
    }
    return ListView.builder(
      itemCount: 7,
      itemBuilder: (c,i){
        if (i<chosen.length) {
          final b = chosen[i];
          return ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text('${b.name}'),
            subtitle: Text('${b.note} • ${b.frequencyHz.toStringAsFixed(2)} Hz • ${(b.cents>=0?'+':'')}${b.cents} ${t.centsShort}'),
          );
        } else {
          return const ListTile(
            leading: Icon(Icons.error_outline, color: Colors.amber),
            title: Text('— missing —'),
          );
        }
      },
    );
  }

  List<int> _selectBest(List<BowlEntry> bowls) {
    if (byNotes) {
      final out = <int>[];
      for (final name in targetOrder) {
        int idx=-1; int best=1<<31;
        for (int i=0;i<bowls.length;i++){
          if (bowls[i].note.startsWith(name) && bowls[i].cents.abs() < best && bowls[i].cents.abs() <= tolerance) {
            idx = i; best = bowls[i].cents.abs();
          }
        }
        if (idx>=0) out.add(idx);
      }
      return out;
    } else {
      final sorted = bowls.asMap().entries.toList()
        ..sort((a,b)=> a.value.frequencyHz.compareTo(b.value.frequencyHz));
      final out = <int>[];
      for (final e in sorted) {
        if (out.length==7) break;
        if (e.value.cents.abs() <= tolerance) out.add(e.key);
      }
      return out;
    }
  }
}
