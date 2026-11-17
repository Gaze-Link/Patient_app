import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static final textScale = ValueNotifier<double>(1);
  static final speechRate = ValueNotifier<double>(0.42);
  static final dwellMilliseconds = ValueNotifier<int>(1500);
  static final darkMode = ValueNotifier<bool>(true);
  static final isResting = ValueNotifier<bool>(false);

  static const _darkModeKey = 'appearance_dark_mode';
  static const _textScaleKey = 'accessibility_text_scale';
  static const _speechRateKey = 'speech_rate';
  static const _dwellMillisecondsKey = 'dwell_milliseconds';

  static Future<void> initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      darkMode.value = preferences.getBool(_darkModeKey) ?? true;
      textScale.value = _validTextScale(
        preferences.getDouble(_textScaleKey),
      );
      speechRate.value = _validSpeechRate(
        preferences.getDouble(_speechRateKey),
      );
      dwellMilliseconds.value = _validDwellMilliseconds(
        preferences.getInt(_dwellMillisecondsKey),
      );
    } catch (_) {
      // Keep the default theme available when local storage is unavailable.
    }
  }

  static Future<void> setDarkMode(bool enabled) async {
    darkMode.value = enabled;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_darkModeKey, enabled);
    } catch (_) {
      // Theme changes still apply for this session if persistence fails.
    }
  }

  /// Applies a validated settings snapshot to the legacy global notifiers.
  ///
  /// The settings feature owns persistence. This bridge remains only while
  /// existing app-wide consumers are migrated away from these notifiers.
  static void apply({
    required bool isDarkMode,
    required double textScaleValue,
    required double speechRateValue,
    required int dwellDurationMilliseconds,
  }) {
    darkMode.value = isDarkMode;
    textScale.value = _validTextScale(textScaleValue);
    speechRate.value = _validSpeechRate(speechRateValue);
    dwellMilliseconds.value = _validDwellMilliseconds(
      dwellDurationMilliseconds,
    );
  }

  static double _validTextScale(double? value) =>
      value != null && value >= 0.9 && value <= 1.35 ? value : 1;

  static double _validSpeechRate(double? value) =>
      value != null && value >= 0.25 && value <= 0.65 ? value : 0.42;

  static int _validDwellMilliseconds(int? value) =>
      value != null && value >= 1000 && value <= 2500 ? value : 1500;
}
