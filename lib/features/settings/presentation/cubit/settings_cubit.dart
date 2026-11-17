import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_preferences.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading, clearError: true));
    try {
      final settings = await _repository.load();
      _applyToLegacyConsumers(settings);
      emit(SettingsState(status: SettingsStatus.ready, settings: settings));
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'تعذّر تحميل الإعدادات. تم استخدام القيم الحالية بأمان.',
        ),
      );
    }
  }

  Future<void> update(AppSettings settings) async {
    final sanitized = settings.sanitized();
    if (!settings.isValid) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: 'قيمة الإعداد غير صالحة.',
        ),
      );
      return;
    }
    if (sanitized == state.settings) return;
    final previousSettings = state.settings;

    emit(
      state.copyWith(
        status: SettingsStatus.saving,
        settings: sanitized,
        clearError: true,
      ),
    );
    try {
      await _repository.save(sanitized);
      _applyToLegacyConsumers(sanitized);
      emit(SettingsState(status: SettingsStatus.ready, settings: sanitized));
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          settings: previousSettings,
          errorMessage: 'تعذّر حفظ الإعدادات. لم يتم تطبيق التغيير.',
        ),
      );
    }
  }

  Future<void> setDarkMode(bool value) =>
      update(state.settings.copyWith(darkMode: value));

  Future<void> setTextScale(double value) =>
      update(state.settings.copyWith(textScale: value));

  Future<void> setSpeechRate(double value) =>
      update(state.settings.copyWith(speechRate: value));

  Future<void> setDwellMilliseconds(int value) =>
      update(state.settings.copyWith(dwellMilliseconds: value));

  void _applyToLegacyConsumers(AppSettings settings) {
    AppPreferences.apply(
      isDarkMode: settings.darkMode,
      textScaleValue: settings.textScale,
      speechRateValue: settings.speechRate,
      dwellDurationMilliseconds: settings.dwellMilliseconds,
    );
  }
}
