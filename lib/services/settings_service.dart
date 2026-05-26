import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class SettingsService extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsService(this._prefs) {
    _loadSettings();
  }

  void _log(String msg) {
    try { FirebaseCrashlytics.instance.log('SettingsService: $msg'); } catch (_) {}
  }

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _taskRemindersEnabled = true;
  String _openRouterModel = 'openai/gpt-oss-120b:free';

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  String get openRouterModel => _openRouterModel;

  void _loadSettings() {
    final themeIndex = _prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    _taskRemindersEnabled = _prefs.getBool('taskRemindersEnabled') ?? true;
    _openRouterModel = _prefs.getString('openRouterModel') ?? 'openai/gpt-oss-120b:free';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('themeMode', mode.index);
    notifyListeners();
    _log('setThemeMode: ${mode.name}');
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool('notificationsEnabled', enabled);
    notifyListeners();
    _log('setNotificationsEnabled: $enabled');
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    _taskRemindersEnabled = enabled;
    await _prefs.setBool('taskRemindersEnabled', enabled);
    notifyListeners();
    _log('setTaskRemindersEnabled: $enabled');
  }

  Future<void> setOpenRouterModel(String model) async {
    _openRouterModel = model;
    await _prefs.setString('openRouterModel', model);
    notifyListeners();
    _log('setOpenRouterModel: $model');
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});
