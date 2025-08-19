import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/localization.dart';
import 'services/preferences.dart';
import 'data/repository.dart';
import 'presentation/screens/tuner_screen.dart';
import 'presentation/screens/bowls_screen.dart';
import 'presentation/screens/set_builder_screen.dart';
import 'presentation/screens/settings_screen.dart';

class TunerApp extends StatelessWidget {
  const TunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.orange,
      fontFamily: 'Roboto',
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Preferences.instance),
        Provider(create: (_) => Repository()),
      ],
      child: MaterialApp(
        title: 'Singing Bowl Tuner',
        theme: theme,
        locale: Preferences.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final t = AppLoc.of(context);
    final pages = const [TunerScreen(), BowlsScreen(), SetBuilderScreen(), SettingsScreen()];
    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.speed), label: t.tuner),
          NavigationDestination(icon: const Icon(Icons.library_music), label: t.myBowls),
          NavigationDestination(icon: const Icon(Icons.grid_view), label: t.setOf7),
          NavigationDestination(icon: const Icon(Icons.settings), label: t.settings),
        ],
      ),
    );
  }
}
