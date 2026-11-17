import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_settings.dart';

abstract interface class SettingsLocalDataSource {
  Future<AppSettings> read();

  Future<void> write(AppSettings settings);
}

class SharedPreferencesSettingsDataSource implements SettingsLocalDataSource {
  SharedPreferencesSettingsDataSource({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const darkModeKey = 'appearance_dark_mode';
  static const textScaleKey = 'accessibility_text_scale';
  static const speechRateKey = 'speech_rate';
  static const dwellMillisecondsKey = 'dwell_milliseconds';

  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<AppSettings> read() async {
    final preferences = await _preferencesLoader();
    return AppSettings(
      darkMode: preferences.getBool(darkModeKey) ?? AppSettings.defaults.darkMode,
      textScale: preferences.getDouble(textScaleKey) ?? AppSettings.defaults.textScale,
      speechRate: preferences.getDouble(speechRateKey) ?? AppSettings.defaults.speechRate,
      dwellMilliseconds:
          preferences.getInt(dwellMillisecondsKey) ??
          AppSettings.defaults.dwellMilliseconds,
    ).sanitized();
  }

  @override
  Future<void> write(AppSettings settings) async {
    if (!settings.isValid) {
      throw ArgumentError.value(settings, 'settings', 'Invalid settings values');
    }
    final preferences = await _preferencesLoader();
    final results = await Future.wait([
      preferences.setBool(darkModeKey, settings.darkMode),
      preferences.setDouble(textScaleKey, settings.textScale),
      preferences.setDouble(speechRateKey, settings.speechRate),
      preferences.setInt(dwellMillisecondsKey, settings.dwellMilliseconds),
    ]);
    if (results.any((saved) => !saved)) {
      throw StateError('Could not save all settings values.');
    }
  }
}
