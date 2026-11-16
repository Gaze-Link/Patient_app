import 'package:flutter/material.dart';

import '../../core/dwell/dwell_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Large, accessible activation target backed by an input-agnostic [DwellController].
///
/// Hover dwell is captured by [MouseRegion] for pointer devices, but the core
/// dwell timing, progress calculation, and activation coordination are completely
/// decoupled into [DwellController] and [DwellCoordinator] for future eye-tracking
/// gaze coordinate providers.
class DwellActionCard extends StatefulWidget {
  const DwellActionCard({
    required this.label,
    required this.onActivate,
    required this.child,
    this.dwellDuration,
    this.allowDuringRestMode = false,
    this.enabled = true,
    this.borderColor,
    this.fillColor,
    this.semanticSelected = false,
    this.borderRadius = AppRadius.card,
    this.contentPadding = const EdgeInsets.all(20),
    this.controller,
    this.targetId,
    super.key,
  });

  final String label;
  final VoidCallback onActivate;
  final Widget child;
  final Duration? dwellDuration;
  final bool allowDuringRestMode;
  final bool enabled;
  final Color? borderColor;
  final Color? fillColor;
  final bool semanticSelected;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;

  /// Optional external [DwellController]. If null, an internal one is managed.
  final DwellController? controller;

  /// Optional stable ID for gaze providers to resolve this action target.
  final Object? targetId;

  @override
  State<DwellActionCard> createState() => _DwellActionCardState();
}

class _DwellActionCardState extends State<DwellActionCard> {
  late DwellController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _isInternalController = false;
    } else {
      _controller = DwellController(
        targetId: widget.targetId,
        allowDuringRestMode: widget.allowDuringRestMode,
        defaultDuration: widget.dwellDuration,
      );
      _isInternalController = true;
    }
    _controller.isEnabled = widget.enabled;
    _controller.addListener(_handleControllerUpdate);
  }

  @override
  void didUpdateWidget(DwellActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller ||
        (widget.controller == null && widget.targetId != oldWidget.targetId)) {
      _controller.removeListener(_handleControllerUpdate);
      if (_isInternalController) {
        _controller.dispose();
      }
      _initController();
    } else {
      _controller.isEnabled = widget.enabled;
    }
  }

  void _handleControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _beginDwell() {
    _controller.startDwell(
      onActivate: widget.onActivate,
      duration: widget.dwellDuration,
    );
  }

  void _endDwell() {
    _controller.cancelDwell();
  }

  void _activateByTap() {
    _controller.triggerImmediate(onActivate: widget.onActivate);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _controller.progress;
    final active = progress > 0;
    final isBlocked = _controller.isBlocked;

    return Semantics(
      button: true,
      selected: widget.semanticSelected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => _beginDwell(),
        onExit: (_) => _endDwell(),
        child: Material(
          color: widget.fillColor ?? AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            side: BorderSide(
              color: active
                  ? AppColors.teal
                  : widget.borderColor ?? AppColors.border,
              width: active ? 3 : 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isBlocked ? null : _activateByTap,
            child: Stack(
              children: [
                Padding(padding: widget.contentPadding, child: widget.child),
                if (active)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      color: AppColors.teal,
                      backgroundColor: AppColors.teal.withValues(alpha: .18),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
