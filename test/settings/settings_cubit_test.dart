import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gaze_app/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:gaze_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:gaze_app/features/settings/domain/models/app_settings.dart';
import 'package:gaze_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:gaze_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:gaze_app/features/settings/presentation/cubit/settings_state.dart';

void main() {
  group('SharedPreferencesSettingsDataSource', () {
    test('returns defaults when no values were stored', () async {
      SharedPreferences.setMockInitialValues({});
      final dataSource = SharedPreferencesSettingsDataSource();

      expect(await dataSource.read(), AppSettings.defaults);
    });

    test('loads saved values and sanitizes invalid stored values', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSettingsDataSource.darkModeKey: false,
        SharedPreferencesSettingsDataSource.textScaleKey: 4.0,
        SharedPreferencesSettingsDataSource.speechRateKey: 0.55,
        SharedPreferencesSettingsDataSource.dwellMillisecondsKey: 1800,
      });
      final dataSource = SharedPreferencesSettingsDataSource();

      expect(
        await dataSource.read(),
        const AppSettings(
          darkMode: false,
          textScale: 1,
          speechRate: 0.55,
          dwellMilliseconds: 1800,
        ),
      );
    });

    test('saves valid values for a later app session', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SettingsRepositoryImpl(
        SharedPreferencesSettingsDataSource(),
      );
      const expected = AppSettings(
        darkMode: false,
        textScale: 1.2,
        speechRate: 0.55,
        dwellMilliseconds: 2000,
      );

      await repository.save(expected);

      expect(await repository.load(), expected);
    });
  });

  group('SettingsCubit', () {
    test('loads saved settings into a ready state', () async {
      const saved = AppSettings(
        darkMode: false,
        textScale: 1.1,
        speechRate: 0.35,
        dwellMilliseconds: 1750,
      );
      final cubit = SettingsCubit(_FakeSettingsRepository(initial: saved));
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, SettingsStatus.ready);
      expect(cubit.state.settings, saved);
    });

    test('saves valid updates and exposes saving then ready states', () async {
      final repository = _FakeSettingsRepository();
      final cubit = SettingsCubit(repository);
      addTearDown(cubit.close);
      final states = <SettingsStatus>[];
      final subscription = cubit.stream.listen((state) => states.add(state.status));
      addTearDown(subscription.cancel);

      await cubit.setDwellMilliseconds(2000);

      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.dwellMilliseconds, 2000);
      expect(states, [SettingsStatus.saving, SettingsStatus.ready]);
    });

    test('rejects invalid values without writing', () async {
      final repository = _FakeSettingsRepository();
      final cubit = SettingsCubit(repository);
      addTearDown(cubit.close);

      await cubit.setTextScale(2);

      expect(cubit.state.status, SettingsStatus.failure);
      expect(repository.saved, isEmpty);
    });

    test('keeps the previous settings when storage fails', () async {
      const previous = AppSettings.defaults;
      final cubit = SettingsCubit(_FakeSettingsRepository(failWrites: true));
      addTearDown(cubit.close);

      await cubit.setSpeechRate(0.55);

      expect(cubit.state.status, SettingsStatus.failure);
      expect(cubit.state.settings, previous);
    });
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({this.initial = AppSettings.defaults, this.failWrites = false});

  final AppSettings initial;
  final bool failWrites;
  final List<AppSettings> saved = [];

  @override
  Future<AppSettings> load() async => initial;

  @override
  Future<void> save(AppSettings settings) async {
    if (failWrites) throw StateError('storage unavailable');
    saved.add(settings);
  }
}
