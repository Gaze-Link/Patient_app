import 'package:flutter/material.dart';

import '../../core/theme/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'dwell_action_card.dart';
import 'figma_icon.dart';

/// A prominent, keyboard/tap and pointer-dwell target for urgent assistance.
class UrgentAssistanceCard extends StatelessWidget {
  const UrgentAssistanceCard({
    required this.onActivate,
    this.compact = false,
    super.key,
  });

  final VoidCallback onActivate;
  final bool compact;

  @override
  Widget build(BuildContext context) => DwellActionCard(
    label: 'مساعدة عاجلة',
    borderColor: AppColors.urgentBorder,
    fillColor: AppColors.urgentSurface,
    onActivate: onActivate,
    contentPadding: EdgeInsets.all(compact ? 10 : 16),
    child: Row(
      children: [
        Container(
          width: compact ? 40 : 52,
          height: compact ? 40 : 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const FigmaIcon(AppAssets.urgent),
        ),
        SizedBox(width: compact ? 10 : 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مساعدة عاجلة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  color: AppColors.urgent,
                  fontSize: compact ? 18 : 22,
                ),
              ),
              if (!compact)
                Text(
                  'للطلب الفوري للمساعدة أو التعبير عن الألم',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
