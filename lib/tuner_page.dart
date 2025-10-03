import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'localization.dart';
import 'models.dart';
import 'native_pitch_detector.dart';

/// Page displaying the real‑time tuner.  It shows the detected note,
/// frequency in Hz, deviation in cents, confidence indicator and a list
/// of detected overtones.
class TunerPage extends StatefulWidget {
  const TunerPage({Key? key}) : super(key: key);

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  final NativePitchDetector _detector = NativePitchDetector();
  StreamSubscription<PitchResult>? _subscription;
  PitchResult? _current;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final autoStart = Provider.of<AppState>(context, listen: false).autoStart;
    if (autoStart) {
      _start();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _detector.stop();
    super.dispose();
  }

  void _start() async {
    if (_running) return;
    final appState = Provider.of<AppState>(context, listen: false);
    setState(() {
      _running = true;
    });
    _subscription = _detector.results.listen(
      (res) {
        setState(() {
          _current = res;
          _error = null;
        });
      },
      onError: (Object err) {
        setState(() {
          _error = err.toString();
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(err.toString())));
        }
        _stop();
      },
    );
    await _detector.start(appState.a4, appState.sampleRate, appState.noiseGate);
  }

  void _stop() async {
    if (!_running) return;
    await _detector.stop();
    await _subscription?.cancel();
    _subscription = null;
    setState(() {
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final res = _current;
    final appState = Provider.of<AppState>(context);
    final note = res != null
        ? frequencyToNoteName(res.frequency, appState.a4)
        : '--';
    final cents = res?.cents ?? 0.0;
    final confidence = res?.confidence ?? 0.0;
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('tuner'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: _buildOvertonesPanel(res?.overtones ?? []),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    note,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    res != null
                        ? '${res.frequency.toStringAsFixed(2)} Hz'
                        : '-- Hz',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    res != null
                        ? '${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(2)} ¢'
                        : '-- ¢',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildGauge(cents),
                  const SizedBox(height: 24),
                  _buildConfidenceBar(confidence),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _running ? null : _start,
                        child: Text(loc.translate('start')),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _running ? _stop : null,
                        child: Text(loc.translate('stop')),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: (res != null && _running)
                            ? () => _saveMeasurement(res!, appState)
                            : null,
                        child: Text(loc.translate('save')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGauge(double cents) {
    final value = (cents + 50) / 100; // 0..1
    return SizedBox(
      height: 24,
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(
          (cents.abs() < 5)
              ? Colors.green
              : (cents.abs() < 15)
                  ? Colors.orange
                  : Colors.red,
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double conf) {
    return Column(
      children: [
        Text('${AppLocalizations.of(context).translate('confidence')}: ${(conf * 100).toStringAsFixed(1)}%'),
        SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: conf.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildOvertonesPanel(List<double> overtones) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('overtones'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: overtones.isEmpty
                ? Center(
                    child: Text(
                      '—',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  )
                : ListView.builder(
                    itemCount: overtones.length,
                    itemBuilder: (context, index) {
                      final freq = overtones[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${index + 1}. ${freq.toStringAsFixed(2)} Hz',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveMeasurement(PitchResult result, AppState appState) async {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.translate('save')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: loc.translate('bowl_name')),
              ),
              TextField(
                controller: commentController,
                decoration: InputDecoration(labelText: loc.translate('comment')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                final measurement = Measurement(
                  note: frequencyToNoteName(result.frequency, appState.a4),
                  frequency: result.frequency,
                  cents: result.cents,
                  dateTime: DateTime.now(),
                  bowlName: nameController.text.isEmpty
                      ? null
                      : nameController.text,
                  comment: commentController.text.isEmpty
                      ? null
                      : commentController.text,
                );
                appState.addMeasurement(measurement);
                Navigator.of(context).pop();
              },
              child: Text(loc.translate('save')),
            ),
          ],
        );
      },
    );
  }
}