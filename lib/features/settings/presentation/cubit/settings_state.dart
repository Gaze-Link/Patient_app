import 'package:equatable/equatable.dart';

import '../../domain/models/app_settings.dart';

enum SettingsStatus { initial, loading, ready, saving, failure }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = AppSettings.defaults,
    this.errorMessage,
  });

  final SettingsStatus status;
  final AppSettings settings;
  final String? errorMessage;

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    String? errorMessage,
    bool clearError = false,
  }) => SettingsState(
    status: status ?? this.status,
    settings: settings ?? this.settings,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
