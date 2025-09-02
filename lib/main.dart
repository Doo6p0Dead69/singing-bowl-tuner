import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'localization.dart';
import 'tuner_page.dart';
import 'journal_page.dart';
import 'set_page.dart';
import 'settings_page.dart';

/// Entry point of the application.  The app uses a [ChangeNotifierProvider]
/// to expose an [AppState] instance throughout the widget tree.  Locale
/// information is loaded from JSON files located in `assets/i18n`.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.loadPreferences();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

/// Root widget of the tuner application.  Provides localization and
/// navigation scaffolding.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Singing Bowl Tuner',
      locale: Locale(appState.locale),
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const RootPage(),
    );
  }
}

/// Top level page managing bottom navigation.  Contains four tabs: tuner,
/// journal, sets and settings.
class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final pages = [
      const TunerPage(),
      const JournalPage(),
      const SetPage(),
      const SettingsPage(),
    ];
    final labels = [
      loc.translate('tuner'),
      loc.translate('journal'),
      loc.translate('sets'),
      loc.translate('settings'),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          for (var i = 0; i < pages.length; i++)
            BottomNavigationBarItem(
              icon: Icon(_navIcon(i)),
              label: labels[i],
            ),
        ],
      ),
    );
  }

  IconData _navIcon(int index) {
    switch (index) {
      case 0:
        return Icons.tune;
      case 1:
        return Icons.history;
      case 2:
        return Icons.queue_music;
      case 3:
      default:
        return Icons.settings;
    }
  }
}