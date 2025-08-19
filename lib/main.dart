import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/localization.dart';
import 'services/preferences.dart';
import 'data/storage.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await Preferences.init();
  runApp(const TunerApp());
}
