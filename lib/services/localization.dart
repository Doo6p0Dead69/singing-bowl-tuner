import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocDelegate();
  static const supportedLocales = [Locale('ru'), Locale('en')];

  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext ctx) => Localizations.of<AppLocalizations>(ctx, AppLocalizations)!;

  String get tuner => _t('tuner');
  String get myBowls => _t('myBowls');
  String get setOf7 => _t('setOf7');
  String get settings => _t('settings');
  String get capture => _t('capture');
  String get a4Equals => _t('a4Equals');
  String get hz => _t('hz');
  String get centsShort => _t('centsShort');
  String get ok => _t('ok');
  String get unsure => _t('unsure');
  String get signal => _t('signal');
  String get filterRange => _t('filterRange');
  String get focusRange => _t('focusRange');
  String get stableOnly => _t('stableOnly');
  String get importJsonCsv => _t('importJsonCsv');
  String get exportJsonCsv => _t('exportJsonCsv');
  String get bowls => _t('bowls');
  String get name => _t('name');
  String get note => _t('note');
  String get freq => _t('freq');
  String get deviation => _t('deviation');
  String get date => _t('date');
  String get comment => _t('comment');
  String get tolerance => _t('tolerance');
  String get modeByNotes => _t('modeByNotes');
  String get modeByFreq => _t('modeByFreq');
  String get missingBowl => _t('missingBowl');
  String get snrTooLow => _t('snrTooLow');
  String get trackingQuality => _t('trackingQuality');
  String get a4Calib => _t('a4Calib');
  String get minMaxHz => _t('minMaxHz');
  String get strictness => _t('strictness');
  String get sensitivity => _t('sensitivity');
  String get decimals => _t('decimals');
  String get latinNotes => _t('latinNotes');
  String get save => _t('save');
  String get cancel => _t('cancel');

  String _t(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key]!;
}

class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocDelegate();
  @override
  bool isSupported(Locale locale) => ['ru', 'en'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.toLanguageTag();
    return AppLocalizations(locale);
  }
  @override
  bool shouldReload(_AppLocDelegate old) => false;
}

typedef AppLoc = AppLocalizations;

const _localizedValues = {
  "ru": {
    "tuner": "Тюнер",
    "myBowls": "Мои чаши",
    "setOf7": "Набор из 7",
    "settings": "Настройки",
    "capture": "Захват",
    "a4Equals": "A4 =",
    "hz": "Гц",
    "centsShort": "ц",
    "ok": "OK",
    "unsure": "неуверенно",
    "signal": "Сигнал",
    "filterRange": "Фильтр диапазона",
    "focusRange": "Рабочий фокус",
    "stableOnly": "Только стабильные тоны",
    "importJsonCsv": "Импорт JSON/CSV",
    "exportJsonCsv": "Экспорт JSON/CSV",
    "bowls": "Чаши",
    "name": "Название",
    "note": "Нота",
    "freq": "Частота",
    "deviation": "Откл.",
    "date": "Дата",
    "comment": "Примечание",
    "tolerance": "Допуск (ц)",
    "modeByNotes": "По нотам C–D–E–F–G–A–B",
    "modeByFreq": "По возрастанию частоты",
    "missingBowl": "не хватает чаши в диапазоне",
    "snrTooLow": "низкий SNR",
    "trackingQuality": "Качество трека",
    "a4Calib": "Калибровка A4 (Гц)",
    "minMaxHz": "Диапазон (Гц)",
    "strictness": "Строгость стабильности (мс)",
    "sensitivity": "Чувствительность",
    "decimals": "Знаков после запятой",
    "latinNotes": "Латинские названия нот",
    "save": "Сохранить",
    "cancel": "Отмена"
  },
  "en": {
    "tuner": "Tuner",
    "myBowls": "My Bowls",
    "setOf7": "Set of 7",
    "settings": "Settings",
    "capture": "Capture",
    "a4Equals": "A4 =",
    "hz": "Hz",
    "centsShort": "c",
    "ok": "OK",
    "unsure": "unsure",
    "signal": "Signal",
    "filterRange": "Range Filter",
    "focusRange": "Focus Range",
    "stableOnly": "Stable tones only",
    "importJsonCsv": "Import JSON/CSV",
    "exportJsonCsv": "Export JSON/CSV",
    "bowls": "Bowls",
    "name": "Name",
    "note": "Note",
    "freq": "Freq",
    "deviation": "Dev.",
    "date": "Date",
    "comment": "Note",
    "tolerance": "Tolerance (cents)",
    "modeByNotes": "By notes C–D–E–F–G–A–B",
    "modeByFreq": "By ascending frequency",
    "missingBowl": "missing bowl in range",
    "snrTooLow": "low SNR",
    "trackingQuality": "Tracking quality",
    "a4Calib": "A4 calibration (Hz)",
    "minMaxHz": "Min–Max (Hz)",
    "strictness": "Stability strictness (ms)",
    "sensitivity": "Sensitivity",
    "decimals": "Fraction digits",
    "latinNotes": "Latin note names",
    "save": "Save",
    "cancel": "Cancel"
  }
};
