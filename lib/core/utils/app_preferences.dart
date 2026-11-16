import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class AppPreferences {
  static final textScale = ValueNotifier<double>(1);
  static final speechRate = ValueNotifier<double>(0.42);
  static final dwellMilliseconds = ValueNotifier<int>(1500);
  static final darkMode = ValueNotifier<bool>(true);
  static final isResting = ValueNotifier<bool>(false);

  static const _darkModeKey = 'appearance_dark_mode';

  static Future<void> initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      darkMode.value = preferences.getBool(_darkModeKey) ?? true;
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
}
