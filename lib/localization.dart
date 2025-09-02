import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Localization class which loads key/value pairs from a JSON asset based on
/// the current locale.  Translations are stored in `assets/i18n/<lang>.json`.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;
  Map<String, dynamic> _localizedStrings = {};

  /// Load translation strings for the current locale.  If the locale file
  /// cannot be found the English strings are used as a fallback.
  Future<bool> load() async {
    final String lang = locale.languageCode;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/i18n/$lang.json');
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      final String jsonString =
          await rootBundle.loadString('assets/i18n/en.json');
      _localizedStrings = json.decode(jsonString) as Map<String, dynamic>;
    }
    return true;
  }

  /// Retrieve a translated string for the provided [key].  If the key is
  /// missing, the key itself is returned.  This allows the UI to function
  /// even if some translations are absent.
  String translate(String key) {
    return _localizedStrings[key] as String? ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

/// Localization delegate responsible for loading [AppLocalizations].
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}