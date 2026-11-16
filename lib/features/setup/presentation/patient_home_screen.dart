import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_padding.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/patient_bottom_nav.dart';
import '../../../shared/widgets/patient_status_chip.dart';
import '../../../shared/widgets/figma_icon.dart';
import '../../../shared/widgets/urgent_assistance_card.dart';
import '../data/patient_category_catalog.dart';
import '../domain/models/patient_category.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key, this.showCategories = false});
  final bool showCategories;

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  void _openCategory(PatientCategory category) {
    if (AppPreferences.isResting.value) return;
    if (category.id == 'composer') {
      context.goNamed('composer');
      return;
    }
    context.goNamed(
      'communication',
      queryParameters: {'category': category.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesOnly = widget.showCategories;
    return Scaffold(
      bottomNavigationBar: PatientBottomNav(
        selected: categoriesOnly ? 'categories' : 'dashboard',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.page,
            14,
            AppPadding.page,
            12,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              final isCompact =
                  constraints.maxHeight < 580 || constraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(categoriesOnly, landscape, constraints.maxWidth),
                  SizedBox(height: isCompact ? 10 : 16),
                  Expanded(
                    child: landscape && constraints.maxWidth >= 700
                        ? Row(
                            children: [
                              Expanded(
                                flex: 7,
                                child: _categoryGrid(isCompact),
                              ),
                              const SizedBox(width: AppPadding.targetGap),
                              if (!categoriesOnly)
                                Expanded(
                                  flex: 4,
                                  child: _sideActions(isCompact),
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          )
                        : Column(
                            children: [
                              if (!categoriesOnly) ...[
                                SizedBox(
                                  height: isCompact ? 78 : 104,
                                  child: _urgentTarget(compact: isCompact),
                                ),
                                SizedBox(height: isCompact ? 8 : 12),
                              ],
                              Expanded(child: _categoryGrid(isCompact)),
                            ],
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

  Widget _header(bool categoriesOnly, bool landscape, double width) {
    final compact = width < 650;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!categoriesOnly && !compact)
          Text(
            'مرحباً بك،',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        Text(
          categoriesOnly ? 'فئات التواصل' : 'ماذا تريد أن تقول؟',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.pageTitle.copyWith(fontSize: compact ? 24 : 30),
        ),
        if (!compact)
          Text(
            categoriesOnly
                ? 'ثبّت نظرك على القسم المطلوب حتى يكتمل المؤشر.'
                : 'خلّي عينك على الاختيار لحد ما يكتمل المؤشر.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body,
          ),
      ],
    );
    if (!landscape && compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: copy),
          const SizedBox(width: 8),
          const PatientStatusChip(compact: true, title: 'جاهز'),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: copy),
        const SizedBox(width: 16),
        PatientStatusChip(compact: compact),
      ],
    );
  }

  Widget _categoryGrid(bool compact) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 520 ? 2 : 2;
      final spacing = compact ? 10.0 : 16.0;
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      final itemHeight = (constraints.maxHeight - spacing) / 2;
      final ratio = itemWidth / itemHeight.clamp(1.0, double.infinity);
      final short = itemHeight < 150;
      return GridView.builder(
        itemCount: patientCategories.length,
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: ratio.clamp(0.9, 3.2),
        ),
        itemBuilder: (context, index) {
          final category = patientCategories[index];
          final iconSize = short ? 38.0 : 58.0;
          return DwellActionCard(
            label: category.label,
            contentPadding: EdgeInsets.all(short ? 10 : 20),
            onActivate: () => _openCategory(category),
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.iconSurface,
                    borderRadius: BorderRadius.circular(short ? 12 : 18),
                  ),
                  child: FigmaIcon(category.asset),
                ),
                SizedBox(width: short ? 10 : 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: short ? 17 : 24,
                        ),
                      ),
                      if (!short) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  Widget _sideActions(bool compact) => Column(
    children: [
      Expanded(child: _urgentTarget(compact: compact)),
      const SizedBox(height: 14),
      SizedBox(
        height: compact ? 76 : 86,
        child: ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.isResting,
          builder: (context, resting, _) => DwellActionCard(
            label: resting ? 'متابعة التواصل' : 'أحتاج إلى راحة',
            allowDuringRestMode: true,
            fillColor: AppColors.surface,
            onActivate: () => AppPreferences.isResting.value = !resting,
            child: Row(
              children: [
                const FigmaIcon(AppAssets.rest),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    resting ? 'الراحة مفعّلة' : 'تحتاج إلى راحة؟',
                    style: AppTextStyles.button,
                  ),
                ),
                Icon(
                  resting ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: AppColors.teal,
                  size: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _urgentTarget({bool compact = false}) => UrgentAssistanceCard(
    compact: compact,
    onActivate: () => context.pushNamed('emergency'),
  );
}
