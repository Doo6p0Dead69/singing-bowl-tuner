import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'localization.dart';
import 'models.dart';

/// Page for calculating sets of seven bowls (C D E F G A B) based on recorded
/// measurements.  The user selects a strategy (plus, minus, balanced) and
/// tolerance.  The resulting set displays the selected measurement for each
/// note and a total score.
class SetPage extends StatefulWidget {
  const SetPage({Key? key}) : super(key: key);

  @override
  State<SetPage> createState() => _SetPageState();
}

class _SetPageState extends State<SetPage> {
  String _strategy = 'balanced';
  double _tolerance = 10.0;
  Map<String, Measurement>? _set;
  double _score = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('sets'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _strategy,
                    items: [
                      DropdownMenuItem(
                          value: 'plus', child: Text(loc.translate('plus'))),
                      DropdownMenuItem(
                          value: 'minus', child: Text(loc.translate('minus'))),
                      DropdownMenuItem(
                          value: 'balanced', child: Text(loc.translate('balanced'))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _strategy = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<double>(
                  value: _tolerance,
                  items: [10.0, 15.0, 20.0]
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.toInt()} ¢'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tolerance = value);
                    }
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    final result = _calculateSet(appState.measurements);
                    setState(() {
                      _set = result.item1;
                      _score = result.item2;
                    });
                  },
                  child: Text(loc.translate('calc_sets')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _set == null
                ? Container()
                : Expanded(
                    child: ListView(
                      children: [
                        for (final note in ['C', 'D', 'E', 'F', 'G', 'A', 'B'])
                          ListTile(
                            title: Text(
                                '$note: ${_set![note]?.frequency.toStringAsFixed(2) ?? '--'} Hz'),
                            subtitle: Text(
                              _set![note] != null
                                  ? '${(_set![note]!.cents >= 0 ? '+' : '')}${_set![note]!.cents.toStringAsFixed(2)} ¢'
                                  : loc.translate('no_measurements'),
                            ),
                          ),
                        ListTile(
                          title: Text('Score: ${_score.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// Compute the best set according to the selected [_strategy] and
  /// [_tolerance].  Returns a map from note to the chosen measurement and the
  /// total score.  If a note has no candidate within tolerance it will be
  /// mapped to null.
  (_SetResult) _calculateSet(List<Measurement> measurements) {
    final result = <String, Measurement?>{};
    double score = 0.0;
    final notes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    for (final n in notes) {
      final candidates = measurements.where((m) => m.note == n).toList();
      // Filter by tolerance
      final valid = candidates
          .where((m) => m.cents.abs() <= _tolerance)
          .toList();
      if (valid.isEmpty) {
        result[n] = null;
        continue;
      }
      Measurement selected;
      if (_strategy == 'plus') {
        valid.sort((a, b) => b.cents.compareTo(a.cents));
        selected = valid.first;
      } else if (_strategy == 'minus') {
        valid.sort((a, b) => a.cents.compareTo(b.cents));
        selected = valid.first;
      } else {
        // balanced: minimal absolute cents
        valid.sort((a, b) => a.cents.abs().compareTo(b.cents.abs()));
        selected = valid.first;
      }
      result[n] = selected;
      score += selected.cents.abs();
    }
    return _SetResult(result, score);
  }
}

/// Private helper class representing the result of set calculation.
class _SetResult {
  _SetResult(this.item1, this.item2);
  final Map<String, Measurement?> item1;
  final double item2;
}