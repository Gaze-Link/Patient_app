import 'package:equatable/equatable.dart';

/// Patient preferences that affect the app's presentation and interaction.
class AppSettings extends Equatable {
  const AppSettings({
    required this.darkMode,
    required this.textScale,
    required this.speechRate,
    required this.dwellMilliseconds,
  });

  static const defaults = AppSettings(
    darkMode: true,
    textScale: 1,
    speechRate: 0.42,
    dwellMilliseconds: 1500,
  );

  final bool darkMode;
  final double textScale;
  final double speechRate;
  final int dwellMilliseconds;

  bool get isValid =>
      textScale >= 0.9 &&
      textScale <= 1.35 &&
      speechRate >= 0.25 &&
      speechRate <= 0.65 &&
      dwellMilliseconds >= 1000 &&
      dwellMilliseconds <= 2500;

  AppSettings copyWith({
    bool? darkMode,
    double? textScale,
    double? speechRate,
    int? dwellMilliseconds,
  }) => AppSettings(
    darkMode: darkMode ?? this.darkMode,
    textScale: textScale ?? this.textScale,
    speechRate: speechRate ?? this.speechRate,
    dwellMilliseconds: dwellMilliseconds ?? this.dwellMilliseconds,
  );

  /// Keeps valid fields and restores the default only for invalid input.
  AppSettings sanitized() => AppSettings(
    darkMode: darkMode,
    textScale: textScale >= 0.9 && textScale <= 1.35
        ? textScale
        : defaults.textScale,
    speechRate: speechRate >= 0.25 && speechRate <= 0.65
        ? speechRate
        : defaults.speechRate,
    dwellMilliseconds:
        dwellMilliseconds >= 1000 && dwellMilliseconds <= 2500
        ? dwellMilliseconds
        : defaults.dwellMilliseconds,
  );

  @override
  List<Object> get props => [
    darkMode,
    textScale,
    speechRate,
    dwellMilliseconds,
  ];
}
