import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'motion_tokens.dart';

/// A subtle, rhythmic speaking waveform indicator for TTS feedback.
///
/// Displays 4 rounded vertical bars that animate when [isSpeaking] is true,
/// giving visual feedback that Arabic speech is actively playing.
class SpeakingWaveform extends StatefulWidget {
  const SpeakingWaveform({
    super.key,
    required this.isSpeaking,
    this.color,
    this.height = 24.0,
    this.barWidth = 4.0,
    this.barSpacing = 3.0,
  });

  final bool isSpeaking;
  final Color? color;
  final double height;
  final double barWidth;
  final double barSpacing;

  @override
  State<SpeakingWaveform> createState() => _SpeakingWaveformState();
}

class _SpeakingWaveformState extends State<SpeakingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isSpeaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpeakingWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _controller.repeat();
      } else {
        _controller.animateTo(0, duration: MotionTokens.durationShort);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MotionTokens.prefersReducedMotion(context);
    final activeColor = widget.color ?? AppColors.teal;
    final totalWidth = 4 * (widget.barWidth + widget.barSpacing);

    return SizedBox(
      width: totalWidth,
      height: widget.height,
      child: TickerMode(
        enabled: !reducedMotion,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(4, (index) {
                double fraction = 0.25;
                if (widget.isSpeaking && !reducedMotion) {
                  final phase = index * (math.pi / 2.5);
                  final wave = math.sin(
                    _controller.value * 2 * math.pi + phase,
                  );
                  fraction = 0.25 + 0.75 * ((wave + 1.0) / 2.0);
                }

                final barHeight = (widget.height * fraction).clamp(
                  4.0,
                  widget.height,
                );

                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: widget.barSpacing / 2,
                  ),
                  width: widget.barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(
                      alpha: widget.isSpeaking ? 1.0 : 0.4,
                    ),
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
