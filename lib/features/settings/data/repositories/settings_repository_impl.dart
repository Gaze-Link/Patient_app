import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  Future<AppSettings> load() => _localDataSource.read();

  @override
  Future<void> save(AppSettings settings) => _localDataSource.write(settings);
}
