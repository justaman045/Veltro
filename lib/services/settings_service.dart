import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsService(this._prefs) {
    _loadSettings();
  }

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;

  void _loadSettings() {
    final themeIndex = _prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool('notificationsEnabled', enabled);
    notifyListeners();
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});
