import 'package:flutter/material.dart';

/// Shared palette interpolated during appearance changes.
abstract final class AppColors {
  static double _darkBlend = 1;

  static Brightness get brightness =>
      _darkBlend < 0.5 ? Brightness.light : Brightness.dark;

  static double get darkBlend => _darkBlend;

  static void setDarkMode(bool value) {
    _darkBlend = value ? 1 : 0;
  }

  static void setAppearanceProgress(double value) {
    _darkBlend = value.clamp(0.0, 1.0);
  }

  static Color _blend(Color dark, Color light) =>
      Color.lerp(light, dark, _darkBlend)!;

  static Color get background =>
      _blend(const Color(0xFF101820), const Color(0xFFF5F8F8));
  static Color get surface =>
      _blend(const Color(0xFF22323F), const Color(0xFFFFFFFF));
  static Color get surfaceRaised =>
      _blend(const Color(0xFF1D2B36), const Color(0xFFE9F0F1));
  static Color get navigation =>
      _blend(const Color(0xFF17232D), const Color(0xFFEAF0F1));
  static Color get border =>
      _blend(const Color(0xFF354956), const Color(0xFFCFDADD));
  static Color get borderStrong =>
      _blend(const Color(0xFF526875), const Color(0xFF9AAEB3));
  static Color get text =>
      _blend(const Color(0xFFF2F6F8), const Color(0xFF172B3A));
  static Color get textMuted =>
      _blend(const Color(0xFFC2CFD7), const Color(0xFF526570));
  static Color get textQuiet =>
      _blend(const Color(0xFFA6B6C1), const Color(0xFF63747B));
  static Color get mint =>
      _blend(const Color(0xFF66D19E), const Color(0xFF28664C));
  static Color get teal =>
      _blend(const Color(0xFF5ED6CE), const Color(0xFF167D83));
  static Color get onPrimary =>
      _blend(const Color(0xFF101820), const Color(0xFFFFFFFF));
  static Color get iconSurface =>
      _blend(const Color(0xFF183E40), const Color(0xFFE2F1F0));
  static Color get greenSurface =>
      _blend(const Color(0xFF17392F), const Color(0xFFE6F3EB));
  static Color get greenBorder =>
      _blend(const Color(0xFF28664C), const Color(0xFF8DBCA0));
  static Color get urgent =>
      _blend(const Color(0xFFFF8A8A), const Color(0xFFB4232E));
  static Color get urgentSurface =>
      _blend(const Color(0xFF45272B), const Color(0xFFFCECEE));
  static Color get urgentBorder =>
      _blend(const Color(0xFF783A40), const Color(0xFFE8A7AD));
}
