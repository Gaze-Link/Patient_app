import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_padding.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/figma_icon.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 520;
            final pagePadding = compact ? 20.0 : AppPadding.page;
            final content = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 690),
              child: Padding(
                padding: EdgeInsets.all(pagePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _welcomeCopy(compact),
                    SizedBox(height: compact ? 14 : 24),
                    _actions(
                      context,
                      compact,
                      (constraints.maxWidth - pagePadding * 2)
                          .clamp(0.0, 330.0)
                          .toDouble(),
                    ),
                  ],
                ),
              ),
            );
            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(child: content),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _welcomeCopy(bool compact) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: compact ? 72 : 104,
        height: compact ? 72 : 104,
        decoration: BoxDecoration(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(child: FigmaIcon(AppAssets.eye)),
      ),
      SizedBox(height: compact ? 12 : 24),
      Text(
        'أهلاً بك في تواصل',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.teal,
          fontSize: 18,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'كلامك مهم، وصوتك يستحق أن يُسمع',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 30,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'تواصل بسهولة باستخدام نظرك. خذ وقتك، وسنكون معك خطوة بخطوة.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18, height: 1.6),
      ),
    ],
  );

  Widget _actions(BuildContext context, bool compact, double width) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: width,
        height: compact ? 64 : 72,
        child: DwellActionCard(
          label: 'ابدأ',
          borderRadius: 12,
          contentPadding: EdgeInsets.zero,
          onActivate: () => context.pushNamed('camera'),
          fillColor: AppColors.teal,
          borderColor: AppColors.teal,
          child: Center(
            child: Text(
              'ابدأ',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: width,
        height: 56,
        child: DwellActionCard(
          label: 'أحتاج مساعدة',
          borderRadius: 12,
          contentPadding: EdgeInsets.zero,
          borderColor: Colors.transparent,
          fillColor: Colors.transparent,
          onActivate: () => context.pushNamed('help'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FigmaIcon(AppAssets.help),
              SizedBox(width: 8),
              Text(
                'أحتاج مساعدة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
