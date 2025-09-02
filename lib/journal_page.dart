import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'localization.dart';
import 'models.dart';

/// Page displaying a list of all recorded measurements.  Measurements can be
/// deleted by tapping the trash icon.  The user can export the list as CSV
/// or JSON using the actions in the app bar.
class JournalPage extends StatelessWidget {
  const JournalPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('journal')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: appState.measurements.isNotEmpty
                ? () => _export(context, appState)
                : null,
          ),
        ],
      ),
      body: appState.measurements.isEmpty
          ? Center(child: Text(loc.translate('no_measurements')))
          : ListView.builder(
              itemCount: appState.measurements.length,
              itemBuilder: (context, index) {
                final m = appState.measurements[index];
                final date = DateFormat('yyyy-MM-dd HH:mm').format(m.dateTime);
                return ListTile(
                  title: Text('${m.note}  ${m.frequency.toStringAsFixed(2)} Hz'),
                  subtitle: Text(
                      '$date  ${(m.cents >= 0 ? '+' : '')}${m.cents.toStringAsFixed(2)} ¢\n${m.bowlName ?? ''}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(context, appState, index),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState appState, int index) async {
    final loc = AppLocalizations.of(context);
    final res = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('delete')),
          content: Text('Delete this measurement?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(loc.translate('delete')),
            ),
          ],
        );
      },
    );
    if (res == true) {
      await appState.removeMeasurement(index);
    }
  }

  Future<void> _export(BuildContext context, AppState appState) async {
    final loc = AppLocalizations.of(context);
    final selection = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(loc.translate('export')),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('csv'),
              child: Text(loc.translate('export_csv')),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('json'),
              child: Text(loc.translate('export_json')),
            ),
          ],
        );
      },
    );
    if (selection == 'csv') {
      final data = appState.exportCsv();
      await Share.share(data, subject: 'tuner_measurements.csv');
    } else if (selection == 'json') {
      final data = appState.exportJson();
      await Share.share(data, subject: 'tuner_measurements.json');
    }
  }
}