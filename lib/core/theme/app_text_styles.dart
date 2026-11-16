import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextTheme get textTheme => ThemeData(brightness: AppColors.brightness)
      .textTheme
      .apply(
        fontFamily: 'Cairo',
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      );

  static TextStyle get pageTitle => TextStyle(
    fontFamily: 'Cairo',
    color: AppColors.text,
    fontSize: 30,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get cardTitle => TextStyle(
    fontFamily: 'Cairo',
    color: AppColors.text,
    fontSize: 24,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get body => TextStyle(
    fontFamily: 'Cairo',
    color: AppColors.textMuted,
    fontSize: 17,
    height: 1.55,
  );

  static TextStyle get button => TextStyle(
    fontFamily: 'Cairo',
    color: AppColors.text,
    fontSize: 19,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );
}
