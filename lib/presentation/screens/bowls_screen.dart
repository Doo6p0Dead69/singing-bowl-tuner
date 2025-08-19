import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repository.dart';
import '../../data/models.dart';
import '../../services/export.dart';
import '../../services/localization.dart';

class BowlsScreen extends StatefulWidget {
  const BowlsScreen({super.key});
  @override
  State<BowlsScreen> createState() => _BowlsScreenState();
}

class _BowlsScreenState extends State<BowlsScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<Repository>();
    final t = AppLoc.of(context);
    final bowls = repo.getAllBowls().toList()
      ..sort((a,b)=> a.frequencyHz.compareTo(b.frequencyHz));
    final filtered = bowls.where((b)=> b.name.toLowerCase().contains(query.toLowerCase()) || b.note.toLowerCase().contains(query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(t.myBowls),
        actions: [
          IconButton(icon: const Icon(Icons.upload_file), onPressed: () async {
            final list = await Exporter.importJsonOrCsv();
            for (final b in list) { await repo.addBowl(b); }
            setState((){});
          }),
          IconButton(icon: const Icon(Icons.download), onPressed: () => Exporter.exportJson(filtered)),
          IconButton(icon: const Icon(Icons.table_chart), onPressed: () => Exporter.exportCsv(filtered)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t.bowls),
              onChanged: (v)=> setState(()=> query = v),
            ),
          ),
          Expanded(child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (c,i){
              final b = filtered[i];
              return ListTile(
                title: Text('${b.name}  •  ${b.note}  (${b.cents>0?'+':''}${b.cents}${t.centsShort})'),
                subtitle: Text('${b.frequencyHz.toStringAsFixed(2)} Hz  —  ${b.createdAt.toLocal()}'),
                trailing: IconButton(icon: const Icon(Icons.delete), onPressed: ()=> b.delete().then((_)=> setState((){}))),
                onTap: () async {
                  await showDialog(context: context, builder: (ctx){
                    final ctrlName = TextEditingController(text: b.name);
                    final ctrlMemo = TextEditingController(text: b.memo);
                    return AlertDialog(
                      title: Text(b.note),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextField(controller: ctrlName, decoration: InputDecoration(labelText: t.name)),
                        TextField(controller: ctrlMemo, decoration: InputDecoration(labelText: t.comment)),
                      ]),
                      actions: [
                        TextButton(onPressed: ()=> Navigator.pop(ctx), child: Text(t.cancel)),
                        ElevatedButton(onPressed: () async {
                          b.name = ctrlName.text; b.memo = ctrlMemo.text; await b.save(); if (mounted) Navigator.pop(ctx);
                          setState((){});
                        }, child: Text(t.save))
                      ],
                    );
                  });
                },
              );
            },
          ))
        ],
      ),
    );
  }
}
