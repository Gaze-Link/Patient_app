import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_assets.dart';
import 'dwell_action_card.dart';
import 'figma_icon.dart';

class PatientBottomNav extends StatelessWidget {
  const PatientBottomNav({required this.selected, super.key});

  final String selected;

  static const _items =
      <({String label, String route, String asset, String activeAsset})>[
        (
          label: 'الرئيسية',
          route: 'dashboard',
          asset: AppAssets.navHomeInactive,
          activeAsset: AppAssets.home,
        ),
        (
          label: 'الفئات',
          route: 'categories',
          asset: AppAssets.categories,
          activeAsset: AppAssets.navCategoriesActive,
        ),
        (
          label: 'تكوين جملة',
          route: 'composer',
          asset: AppAssets.navSentence,
          activeAsset: AppAssets.navSentenceActive,
        ),
        (
          label: 'المزيد',
          route: 'settings',
          asset: AppAssets.more,
          activeAsset: AppAssets.more,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 500 || size.height < 450;
    return Container(
      height: compact ? 60 : 76,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.navigation,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (final item in _items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Semantics(
                  button: true,
                  selected: item.route == selected,
                  label: item.label,
                  child: DwellActionCard(
                    label: item.label,
                    targetId: 'bottom-nav-${item.route}',
                    enabled: item.route != selected,
                    semanticSelected: item.route == selected,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: compact ? 2 : 6,
                    ),
                    borderRadius: 14,
                    borderColor: Colors.transparent,
                    fillColor: item.route == selected
                        ? AppColors.greenSurface
                        : Colors.transparent,
                    onActivate: () => context.goNamed(item.route),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: compact ? 20 : 24,
                          height: compact ? 20 : 24,
                          child: FigmaIcon(
                            item.route == selected
                                ? item.activeAsset
                                : item.asset,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: compact ? 10 : 14,
                            height: compact ? 1 : null,
                            color: item.route == selected
                                ? AppColors.teal
                                : AppColors.textMuted,
                            fontWeight: item.route == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
