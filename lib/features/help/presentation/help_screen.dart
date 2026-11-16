import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/dwell_back_button.dart';
import '../../../shared/widgets/patient_status_chip.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _items =
      <({String title, String detail, IconData icon, String route})>[
        (
          title: 'الكاميرا غير مسموح بها',
          detail: 'افتح إعدادات الجهاز واسمح للتطبيق باستخدام الكاميرا.',
          icon: Icons.videocam_outlined,
          route: 'camera',
        ),
        (
          title: 'الوجه غير ظاهر',
          detail: 'عدّل وضع الجهاز بهدوء حتى يظهر الوجه والعينان.',
          icon: Icons.face_outlined,
          route: 'camera',
        ),
        (
          title: 'أحتاج إعادة المعايرة',
          detail: 'أعد خطوات المعايرة التجريبية قبل المتابعة.',
          icon: Icons.center_focus_strong_rounded,
          route: 'calibration',
        ),
        (
          title: 'الصوت غير متاح',
          detail: 'تحقق من تثبيت صوت عربي في إعدادات الجهاز.',
          icon: Icons.volume_up_outlined,
          route: 'settings',
        ),
      ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('المساعدة واستعادة التتبّع'),
      leading: const DwellBackButton(),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر المشكلة التي تظهر لك',
                  style: AppTextStyles.pageTitle,
                ),
                Text(
                  'هذه الإرشادات لا تتصل بجهاز تتبّع خارجي.',
                  style: AppTextStyles.body,
                ),
              ],
            );
            final status = PatientStatusChip(
              compact: compact,
              title: 'تتبّع تجريبي',
              subtitle: 'بالماوس أو اللمس',
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (compact) ...[
                  heading,
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: status,
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(child: heading),
                      status,
                    ],
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    itemCount: _items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 900 ? 2 : 1,
                      mainAxisExtent: 112,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return DwellActionCard(
                        label: item.title,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: compact ? 10 : 20,
                          vertical: compact ? 10 : 14,
                        ),
                        onActivate: () => context.pushNamed(item.route),
                        child: Row(
                          children: [
                            Icon(item.icon, size: 34, color: AppColors.teal),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.button,
                                  ),
                                  Text(
                                    item.detail,
                                    maxLines: compact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
