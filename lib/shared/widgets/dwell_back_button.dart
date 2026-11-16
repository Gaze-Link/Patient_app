import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'dwell_action_card.dart';

/// A reusable back button that supports both mouse/gaze dwell and immediate tap.
class DwellBackButton extends StatelessWidget {
  const DwellBackButton({
    super.key,
    this.onPressed,
    this.fallbackRoute = 'dashboard',
    this.color,
  });

  /// Optional custom callback. If omitted, uses [context.pop] or navigates to [fallbackRoute].
  final VoidCallback? onPressed;

  /// Route to navigate to if the navigation stack cannot be popped.
  final String fallbackRoute;

  /// Custom icon and text color.
  final Color? color;

  void _handleBack(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
      context.goNamed(fallbackRoute);
    } catch (_) {
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textMuted;

    return Center(
      child: SizedBox(
        width: 52,
        height: 48,
        child: DwellActionCard(
          label: 'رجوع',
          borderRadius: 14,
          contentPadding: EdgeInsets.zero,
          borderColor: Colors.transparent,
          fillColor: Colors.transparent,
          onActivate: () => _handleBack(context),
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              color: effectiveColor,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
