import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'localization.dart';
import 'models.dart';
import 'native_pitch_detector.dart';

/// Page allowing the user to configure application settings such as A4 tuning,
/// language, noise gate, sample rate and auto start.  Also provides a
/// reference calibration button which sets A4 to the currently detected
/// frequency (if stable).
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language selector
          ListTile(
            title: Text(loc.translate('select_language')),
            trailing: DropdownButton<String>(
              value: appState.locale,
              items: const [
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) {
                  appState.setLocale(value);
                }
              },
            ),
          ),
          const Divider(),
          // A4 tuning
          ListTile(
            title: Text('${loc.translate('tuning_a4')}: ${appState.a4.toStringAsFixed(1)}'),
            subtitle: Slider(
              min: 415,
              max: 466,
              divisions: 51,
              value: appState.a4,
              onChanged: (value) {
                setState(() => appState.a4 = value);
              },
              onChangeEnd: (_) => appState.savePreferences(),
            ),
          ),
          const Divider(),
          // Sample rate
          ListTile(
            title: Text(loc.translate('sample_rate')),
            trailing: DropdownButton<double>(
              value: appState.sampleRate,
              items: const [
                DropdownMenuItem(value: 44100.0, child: Text('44.1 kHz')),
                DropdownMenuItem(value: 48000.0, child: Text('48 kHz')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => appState.sampleRate = value);
                  appState.savePreferences();
                }
              },
            ),
          ),
          const Divider(),
          // Noise gate
          SwitchListTile(
            title: Text(loc.translate('noise_gate')),
            value: appState.noiseGate,
            onChanged: (value) {
              setState(() => appState.noiseGate = value);
              appState.savePreferences();
            },
          ),
          const Divider(),
          // Auto start
          SwitchListTile(
            title: Text(loc.translate('autosave')),
            value: appState.autoStart,
            onChanged: (value) {
              setState(() => appState.autoStart = value);
              appState.savePreferences();
            },
          ),
          const Divider(),
          // Reference calibration
          ListTile(
            title: Text(loc.translate('reference_calibration')),
            subtitle: Text('Set A4 to current frequency'),
            trailing: ElevatedButton(
              onPressed: () async {
                final detector = NativePitchDetector();
                // Wait one update of pitch to calibrate
                double? freq;
                final sub = detector.results.listen((res) {
                  freq = res.frequency;
                });
                // Wait 500ms
                await Future.delayed(const Duration(milliseconds: 500));
                await sub.cancel();
                if (freq != null && freq! > 200 && freq! < 600) {
                  setState(() => appState.a4 = freq!);
                  await appState.savePreferences();
                }
              },
              child: Text(loc.translate('apply')),
            ),
          ),
        ],
      ),
    );
  }
}