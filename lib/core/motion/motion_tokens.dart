import 'package:flutter/widgets.dart';

/// Design tokens for subtle, accessible animations throughout the app.
///
/// Motion rule for eye-gaze / dwell interfaces:
/// UI elements MUST NOT shift position, resize, or move during dwell countdown
/// because movement disrupts eye-tracking fixation and pointer stability.
abstract final class MotionTokens {
  // Standard Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationShort = Duration(milliseconds: 200);
  static const Duration durationMedium = Duration(milliseconds: 350);
  static const Duration durationLong = Duration(milliseconds: 500);

  // Smooth Curves
  static const Curve curveEaseOut = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve curveEaseInOut = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve curveDecelerate = Curves.easeOutCubic;

  /// Check whether the user prefers reduced motion or accessibility features
  /// that disallow non-essential animations.
  static bool prefersReducedMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    if (media == null) return false;
    return media.accessibleNavigation || media.disableAnimations;
  }
}
