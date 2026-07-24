import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 单位制（2026-07-24 拍板：全局单套，不支持房间/瓷砖混用）。
enum UnitSystem { imperial, metric }

/// 设置项：单位制 / 语言覆盖 / 外观 / 货币符号。全部持久化。
class SettingsController extends ChangeNotifier {
  static const _kUnit = 'unit_system';
  static const _kLocale = 'locale_override';
  static const _kTheme = 'theme_mode';
  static const _kCurrency = 'currency_symbol';

  /// 地区默认为英制的国家/地区（美国、利比里亚、缅甸）。
  static const _imperialRegions = {'US', 'LR', 'MM'};

  final SharedPreferences _prefs;

  UnitSystem? _explicitUnit;
  Locale? _localeOverride;
  ThemeMode _themeMode = ThemeMode.system;
  String _currencySymbol = r'$';

  SettingsController(this._prefs) {
    final unit = _prefs.getString(_kUnit);
    _explicitUnit = switch (unit) {
      'imperial' => UnitSystem.imperial,
      'metric' => UnitSystem.metric,
      _ => null,
    };
    final tag = _prefs.getString(_kLocale);
    _localeOverride = tag == null ? null : Locale(tag);
    _themeMode = switch (_prefs.getString(_kTheme)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _currencySymbol = _prefs.getString(_kCurrency) ?? r'$';
  }

  /// 用户显式选择的单位制；null 表示跟随地区默认。
  UnitSystem? get explicitUnitSystem => _explicitUnit;

  /// 结合地区解析出实际生效的单位制。
  UnitSystem effectiveUnitSystem(Locale locale) {
    if (_explicitUnit != null) return _explicitUnit!;
    return _imperialRegions.contains(locale.countryCode)
        ? UnitSystem.imperial
        : UnitSystem.metric;
  }

  Locale? get localeOverride => _localeOverride;
  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;

  Future<void> setUnitSystem(UnitSystem unit) async {
    _explicitUnit = unit;
    notifyListeners();
    await _prefs.setString(_kUnit, unit.name);
  }

  /// null = 跟随系统语言。
  Future<void> setLocaleOverride(Locale? locale) async {
    _localeOverride = locale;
    notifyListeners();
    if (locale == null) {
      await _prefs.remove(_kLocale);
    } else {
      await _prefs.setString(_kLocale, locale.languageCode);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol.isEmpty ? r'$' : symbol;
    notifyListeners();
    await _prefs.setString(_kCurrency, _currencySymbol);
  }
}
