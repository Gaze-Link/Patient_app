import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PatientStatusChip extends StatelessWidget {
  const PatientStatusChip({
    this.title = 'التتبّع يعمل',
    this.subtitle = 'جاهز للاختيار بالنظر',
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 44 : 64),
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greenSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greenBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          if (compact)
            Text(
              title,
              style: TextStyle(
                color: AppColors.mint,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.mint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
