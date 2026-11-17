import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/patient_bottom_nav.dart';
import '../data/datasources/settings_local_data_source.dart';
import '../data/repositories/settings_repository_impl.dart';
import 'cubit/settings_cubit.dart';
import 'cubit/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SettingsCubit(
      SettingsRepositoryImpl(SharedPreferencesSettingsDataSource()),
    );
    unawaited(_cubit.load());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _cubit,
    child: const _SettingsView(),
  );
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) => BlocBuilder<SettingsCubit, SettingsState>(
    builder: (context, state) {
      final settings = state.settings;
      final isBusy = state.status == SettingsStatus.loading ||
          state.status == SettingsStatus.saving;
      final cubit = context.read<SettingsCubit>();
      return Scaffold(
        bottomNavigationBar: const PatientBottomNav(selected: 'settings'),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('الإعدادات وإمكانية الوصول', style: AppTextStyles.pageTitle),
                Text(
                  'يتم حفظ التغييرات واستعادتها عند فتح التطبيق مرة أخرى.',
                  style: AppTextStyles.body,
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _SettingsMessage(message: state.errorMessage!),
                ],
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      _AppearanceControl(
                        darkMode: settings.darkMode,
                        enabled: !isBusy,
                        onChanged: (value) => unawaited(cubit.setDarkMode(value)),
                      ),
                      const SizedBox(height: 12),
                      _PreferenceControl(
                        title: 'حجم النص',
                        value: settings.textScale,
                        minimum: 0.9,
                        maximum: 1.35,
                        step: 0.1,
                        enabled: !isBusy,
                        valueLabel: (value) => value > 1.1
                            ? 'كبير'
                            : value < 1
                            ? 'أصغر'
                            : 'قياسي',
                        onChanged: (value) => unawaited(cubit.setTextScale(value)),
                      ),
                      const SizedBox(height: 12),
                      _PreferenceControl(
                        title: 'سرعة الصوت',
                        value: settings.speechRate,
                        minimum: 0.25,
                        maximum: 0.65,
                        step: 0.1,
                        enabled: !isBusy,
                        valueLabel: (value) => value < 0.38
                            ? 'بطيئة'
                            : value > 0.52
                            ? 'سريعة'
                            : 'متوسطة',
                        onChanged: (value) => unawaited(cubit.setSpeechRate(value)),
                      ),
                      const SizedBox(height: 12),
                      _DwellControl(
                        value: settings.dwellMilliseconds,
                        enabled: !isBusy,
                        onChanged: (value) =>
                            unawaited(cubit.setDwellMilliseconds(value)),
                      ),
                      const SizedBox(height: 14),
                      const _ReadOnlySetting(
                        title: 'صوت القراءة',
                        value: 'العربية — مصر (تلقائي حسب الجهاز)',
                      ),
                      const SizedBox(height: 14),
                      const _ReadOnlySetting(
                        title: 'اختيار النظر',
                        value: 'محاكاة بالماوس/اللمس؛ تتبّع العين الحقيقي غير متصل',
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 72,
                        child: DwellActionCard(
                          label: 'المساعدة واستعادة التتبّع',
                          borderRadius: 16,
                          onActivate: () => context.pushNamed('help'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.help_outline_rounded),
                              SizedBox(width: 8),
                              Text(
                                'المساعدة واستعادة التتبّع',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SettingsMessage extends StatelessWidget {
  const _SettingsMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.urgent.withValues(alpha: .12),
      border: Border.all(color: AppColors.urgent.withValues(alpha: .45)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message, style: AppTextStyles.body),
  );
}

class _AppearanceControl extends StatelessWidget {
  const _AppearanceControl({
    required this.darkMode,
    required this.enabled,
    required this.onChanged,
  });

  final bool darkMode;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => DwellActionCard(
    label: darkMode ? 'التبديل إلى الوضع الفاتح' : 'التبديل إلى الوضع الداكن',
    enabled: enabled,
    borderRadius: 18,
    contentPadding: EdgeInsets.zero,
    onActivate: () => onChanged(!darkMode),
    child: SwitchListTile.adaptive(
      value: darkMode,
      onChanged: enabled ? onChanged : null,
      activeTrackColor: AppColors.teal,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text('مظهر التطبيق', style: AppTextStyles.button),
      subtitle: Text(
        darkMode ? 'الوضع الداكن' : 'الوضع الفاتح',
        style: AppTextStyles.body,
      ),
    ),
  );
}

class _PreferenceControl extends StatelessWidget {
  const _PreferenceControl({
    required this.title,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.step,
    required this.enabled,
    required this.valueLabel,
    required this.onChanged,
  });

  final String title;
  final double value;
  final double minimum;
  final double maximum;
  final double step;
  final bool enabled;
  final String Function(double) valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => _SettingRow(
    title: title,
    value: valueLabel(value),
    onDecrease: enabled && value > minimum
        ? () => onChanged((value - step).clamp(minimum, maximum))
        : null,
    onIncrease: enabled && value < maximum
        ? () => onChanged((value + step).clamp(minimum, maximum))
        : null,
  );
}

class _DwellControl extends StatelessWidget {
  const _DwellControl({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => _SettingRow(
    title: 'مدة تثبيت النظر',
    value: '${(value / 1000).toStringAsFixed(1)} ثانية — قيمة تجريبية',
    onDecrease: enabled && value > 1000 ? () => onChanged(value - 250) : null,
    onIncrease: enabled && value < 2500 ? () => onChanged(value + 250) : null,
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String title;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$title، $value',
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.button),
                Text(value, style: AppTextStyles.body),
              ],
            ),
          ),
          _StepButton(
            label: 'تقليل $title',
            icon: Icons.remove_rounded,
            onPressed: onDecrease,
          ),
          const SizedBox(width: 10),
          _StepButton(
            label: 'زيادة $title',
            icon: Icons.add_rounded,
            onPressed: onIncrease,
          ),
        ],
      ),
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 60,
    child: DwellActionCard(
      label: label,
      enabled: onPressed != null,
      contentPadding: EdgeInsets.zero,
      fillColor: AppColors.surfaceRaised,
      onActivate: () => onPressed?.call(),
      child: Center(child: Icon(icon, size: 30, color: AppColors.text)),
    ),
  );
}

class _ReadOnlySetting extends StatelessWidget {
  const _ReadOnlySetting({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.button)),
        Text(value, style: TextStyle(color: AppColors.textMuted)),
      ],
    ),
  );
}
