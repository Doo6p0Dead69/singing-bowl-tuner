import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences extends ChangeNotifier {
  Preferences._();
  static final Preferences instance = Preferences._();

  static const _kA4 = 'a4';
  static const _kMinHz = 'min_hz';
  static const _kMaxHz = 'max_hz';
  static const _kFocusMinHz = 'focus_min_hz';
  static const _kFocusMaxHz = 'focus_max_hz';
  static const _kStableMs = 'stable_ms';
  static const _kSensitivity = 'sensitivity';
  static const _kDecimals = 'decimals';
  static const _kStableOnly = 'stable_only';
  static const _kLocale = 'locale';

  late SharedPreferences _sp;

  static Future<void> init() async {
    instance._sp = await SharedPreferences.getInstance();
  }

  Locale? get locale {
    final code = _sp.getString(_kLocale);
    if (code == null) return const Locale('ru');
    return Locale(code);
  }

  set locale(Locale? v) {
    if (v == null) return;
    _sp.setString(_kLocale, v.languageCode);
    notifyListeners();
  }

  double get a4 => _sp.getDouble(_kA4) ?? 440.0;
  set a4(double v){ _sp.setDouble(_kA4, v); notifyListeners(); }

  double get minHz => _sp.getDouble(_kMinHz) ?? 60;
  set minHz(double v){ _sp.setDouble(_kMinHz, v); notifyListeners(); }
  double get maxHz => _sp.getDouble(_kMaxHz) ?? 1200;
  set maxHz(double v){ _sp.setDouble(_kMaxHz, v); notifyListeners(); }

  double get focusMinHz => _sp.getDouble(_kFocusMinHz) ?? 80;
  set focusMinHz(double v){ _sp.setDouble(_kFocusMinHz, v); notifyListeners(); }
  double get focusMaxHz => _sp.getDouble(_kFocusMaxHz) ?? 600;
  set focusMaxHz(double v){ _sp.setDouble(_kFocusMaxHz, v); notifyListeners(); }

  int get stableMs => _sp.getInt(_kStableMs) ?? 350;
  set stableMs(int v){ _sp.setInt(_kStableMs, v); notifyListeners(); }

  double get sensitivity => _sp.getDouble(_kSensitivity) ?? 0.5; // 0..1
  set sensitivity(double v){ _sp.setDouble(_kSensitivity, v); notifyListeners(); }

  int get decimals => _sp.getInt(_kDecimals) ?? 1;
  set decimals(int v){ _sp.setInt(_kDecimals, v); notifyListeners(); }

  bool get stableOnly => _sp.getBool(_kStableOnly) ?? true;
  set stableOnly(bool v){ _sp.setBool(_kStableOnly, v); notifyListeners(); }
}
