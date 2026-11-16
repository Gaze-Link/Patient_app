import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/communication_option.dart';

class CommunicationPhraseTile extends StatelessWidget {
  const CommunicationPhraseTile({
    required this.option,
    required this.isHighlighted,
    required this.isSelected,
    required this.dwellProgress,
    required this.onTap,
    super.key,
  });
  final CommunicationOption option;
  final bool isHighlighted;
  final bool isSelected;
  final double dwellProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: isSelected,
    label: option.label,
    child: Material(
      color: isHighlighted ? AppColors.surfaceRaised : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isHighlighted ? AppColors.teal : AppColors.border,
          width: isHighlighted ? 3 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 110;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 18,
                      vertical: compact ? 8 : 18,
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: compact ? 18 : 24,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (dwellProgress > 0 && dwellProgress < 1)
              Align(
                alignment: Alignment.bottomCenter,
                child: LinearProgressIndicator(
                  value: dwellProgress,
                  minHeight: 6,
                  color: AppColors.teal,
                  backgroundColor: AppColors.teal.withValues(alpha: .18),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
