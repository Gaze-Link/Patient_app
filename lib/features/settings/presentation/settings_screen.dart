import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../shared/widgets/patient_bottom_nav.dart';
import '../../../shared/widgets/dwell_action_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const PatientBottomNav(selected: 'settings'),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الإعدادات وإمكانية الوصول', style: AppTextStyles.pageTitle),
            Text(
              'تغييرات واضحة يمكن تعديلها بأمان. تحفظ هذه القيم خلال الجلسة الحالية.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                children: [
                  _AppearanceControl(),
                  const SizedBox(height: 12),
                  _PreferenceControl(
                    title: 'حجم النص',
                    value: AppPreferences.textScale,
                    minimum: 0.9,
                    maximum: 1.35,
                    step: 0.1,
                    valueLabel: (value) => value > 1.1
                        ? 'كبير'
                        : value < 1
                        ? 'أصغر'
                        : 'قياسي',
                  ),
                  const SizedBox(height: 12),
                  _PreferenceControl(
                    title: 'سرعة الصوت',
                    value: AppPreferences.speechRate,
                    minimum: 0.25,
                    maximum: 0.65,
                    step: 0.1,
                    valueLabel: (value) => value < 0.38
                        ? 'بطيئة'
                        : value > 0.52
                        ? 'سريعة'
                        : 'متوسطة',
                  ),
                  const SizedBox(height: 12),
                  _DwellControl(),
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
}

class _AppearanceControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AppPreferences.darkMode,
    builder: (context, darkMode, _) => DwellActionCard(
      label: darkMode ? 'التبديل إلى الوضع الفاتح' : 'التبديل إلى الوضع الداكن',
      borderRadius: 18,
      contentPadding: EdgeInsets.zero,
      onActivate: () => unawaited(AppPreferences.setDarkMode(!darkMode)),
      child: SwitchListTile.adaptive(
        value: darkMode,
        onChanged: (enabled) => unawaited(AppPreferences.setDarkMode(enabled)),
        activeTrackColor: AppColors.teal,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text('مظهر التطبيق', style: AppTextStyles.button),
        subtitle: Text(
          darkMode ? 'الوضع الداكن' : 'الوضع الفاتح',
          style: AppTextStyles.body,
        ),
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
    required this.valueLabel,
  });
  final String title;
  final ValueNotifier<double> value;
  final double minimum;
  final double maximum;
  final double step;
  final String Function(double) valueLabel;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: value,
    builder: (context, current, _) => _SettingRow(
      title: title,
      value: valueLabel(current),
      onDecrease: current > minimum
          ? () => value.value = (current - step).clamp(minimum, maximum)
          : null,
      onIncrease: current < maximum
          ? () => value.value = (current + step).clamp(minimum, maximum)
          : null,
    ),
  );
}

class _DwellControl extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: AppPreferences.dwellMilliseconds,
    builder: (context, current, _) => _SettingRow(
      title: 'مدة تثبيت النظر',
      value: '${(current / 1000).toStringAsFixed(1)} ثانية — قيمة تجريبية',
      onDecrease: current > 1000
          ? () => AppPreferences.dwellMilliseconds.value = current - 250
          : null,
      onIncrease: current < 2500
          ? () => AppPreferences.dwellMilliseconds.value = current + 250
          : null,
    ),
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
