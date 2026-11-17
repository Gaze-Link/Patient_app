import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dwell/dwell_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_preferences.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/dwell_back_button.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  static const _pointCount = 9;
  final List<Offset> _simulatedSamples = [];
  late final DwellController _dwellController = DwellController(
    targetId: 'calibration_target',
  );
  int? _activePoint;
  Offset? _lastPointerPosition;

  bool get _isComplete => _simulatedSamples.length == _pointCount;

  @override
  void initState() {
    super.initState();
    _dwellController.addListener(_handleDwellUpdate);
    AppPreferences.isResting.addListener(_handleRestModeChanged);
  }

  void _handleDwellUpdate() {
    if (mounted) setState(() {});
  }

  void _handleRestModeChanged() {
    if (AppPreferences.isResting.value) {
      setState(_cancelDwell);
    }
  }

  void _startDwell(int index, Offset globalPosition) {
    if (_activePoint == index) {
      _lastPointerPosition = globalPosition;
      return;
    }
    if (_isComplete || index != _simulatedSamples.length) {
      _cancelDwell();
      return;
    }

    _lastPointerPosition = globalPosition;
    _activePoint = index;
    _dwellController.startDwell(
      onActivate: () =>
          _recordPoint(index, _lastPointerPosition ?? globalPosition),
    );
  }

  void _updateDwellPosition(int index, Offset globalPosition) {
    if (_activePoint == index) _lastPointerPosition = globalPosition;
  }

  void _cancelDwell() {
    _dwellController.cancelDwell();
    _activePoint = null;
  }

  void _recordPoint(int index, Offset globalPosition) {
    if (!mounted || index != _simulatedSamples.length) return;
    final screenSize = MediaQuery.sizeOf(context);
    final normalized = Offset(
      (globalPosition.dx / screenSize.width).clamp(0.0, 1.0),
      (globalPosition.dy / screenSize.height).clamp(0.0, 1.0),
    );
    setState(() {
      _simulatedSamples.add(normalized);
      _activePoint = null;
    });
  }

  void _recordTap(int index, TapDownDetails details) {
    if (_isComplete || index != _simulatedSamples.length) return;
    _cancelDwell();
    _recordPoint(index, details.globalPosition);
  }

  void _restartCalibration() {
    setState(() {
      _simulatedSamples.clear();
      _activePoint = null;
      _dwellController.cancelDwell();
    });
  }

  @override
  void dispose() {
    _dwellController.removeListener(_handleDwellUpdate);
    _dwellController.dispose();
    AppPreferences.isResting.removeListener(_handleRestModeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 480;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: compact ? 44 : kToolbarHeight,
        title: const Text('معايرة تتبّع العين'),
        leading: const DwellBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            compact ? 4 : 12,
            20,
            compact ? 8 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isComplete
                    ? 'اتسجلت ٩ من ٩ نقاط (محاكاة)'
                    : 'ثبّت عينك على النقطة ${_simulatedSamples.length + 1} من ٩',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 6),
                Text(
                  'ثبّت المؤشر أو المس النقطة. هذه معايرة تجريبية ولا تستخدم بيانات عين حقيقية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, height: 1.4),
                ),
              ],
              SizedBox(height: compact ? 6 : 12),
              LinearProgressIndicator(
                value: _simulatedSamples.length / _pointCount,
                minHeight: compact ? 4 : 6,
                borderRadius: BorderRadius.circular(8),
                color: AppColors.teal,
                backgroundColor: AppColors.surface,
              ),
              SizedBox(height: compact ? 6 : 12),
              Expanded(
                child: _isComplete
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: compact ? 72 : 88,
                                height: compact ? 72 : 88,
                                decoration: BoxDecoration(
                                  color: AppColors.greenSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.greenBorder,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: AppColors.mint,
                                  size: compact ? 40 : 48,
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 16),
                              Text(
                                'تم تأكيد النتيجة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: compact ? 22 : 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mint,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'جاهز للتواصل',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: compact ? 18 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'تمت معايرة النقاط بنجاح وجاهز لاستخدام التطبيق.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 15,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final targetDiameter = math
                              .min(
                                112.0,
                                math.min(
                                  constraints.maxWidth / 3,
                                  constraints.maxHeight / 3,
                                ),
                              )
                              .clamp(44.0, 112.0)
                              .toDouble();
                          final edgeX =
                              (1 - targetDiameter / constraints.maxWidth).clamp(
                                0.0,
                                1.0,
                              );
                          final edgeY =
                              (1 - targetDiameter / constraints.maxHeight)
                                  .clamp(0.0, 1.0);
                          return Stack(
                            children: [
                              for (var index = 0; index < 9; index++)
                                Align(
                                  alignment: Alignment(
                                    index % 3 == 0
                                        ? -edgeX
                                        : index % 3 == 1
                                        ? 0
                                        : edgeX,
                                    index ~/ 3 == 0
                                        ? -edgeY
                                        : index ~/ 3 == 1
                                        ? 0
                                        : edgeY,
                                  ),
                                  child: _CalibrationTarget(
                                    index: index,
                                    diameter: targetDiameter,
                                    isCurrent:
                                        !_isComplete &&
                                        index == _simulatedSamples.length,
                                    isRecorded:
                                        index < _simulatedSamples.length,
                                    progress: _activePoint == index
                                        ? _dwellController.progress
                                        : 0,
                                    onEnter: (position) =>
                                        _startDwell(index, position),
                                    onHover: (position) =>
                                        _updateDwellPosition(index, position),
                                    onExit: (_) {
                                      if (_activePoint == index) {
                                        setState(_cancelDwell);
                                      }
                                    },
                                    onTapDown: (details) =>
                                        _recordTap(index, details),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
              ),
              SizedBox(height: compact ? 6 : 12),
              Row(
                children: [
                  if (_isComplete) ...[
                    Expanded(
                      child: SizedBox(
                        height: compact ? 48 : 58,
                        child: DwellActionCard(
                          label: 'إعادة المعايرة',
                          contentPadding: EdgeInsets.zero,
                          onActivate: _restartCalibration,
                          child: const Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded),
                                  SizedBox(width: 8),
                                  Text('إعادة المعايرة'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: SizedBox(
                      height: compact ? 48 : 58,
                      child: DwellActionCard(
                        label: 'ابدأ التواصل',
                        enabled: _isComplete,
                        contentPadding: EdgeInsets.zero,
                        fillColor: AppColors.teal,
                        onActivate: () => context.goNamed('dashboard'),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.onPrimary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ابدأ التواصل',
                                  style: TextStyle(color: AppColors.onPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalibrationTarget extends StatelessWidget {
  const _CalibrationTarget({
    required this.index,
    required this.diameter,
    required this.isCurrent,
    required this.isRecorded,
    required this.progress,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
    required this.onTapDown,
  });

  final int index;
  final double diameter;
  final bool isCurrent;
  final bool isRecorded;
  final double progress;
  final ValueChanged<Offset> onEnter;
  final ValueChanged<Offset> onHover;
  final ValueChanged<Offset> onExit;
  final GestureTapDownCallback onTapDown;

  @override
  Widget build(BuildContext context) {
    final targetSize = isRecorded
        ? 36.0
        : isCurrent
        ? 36.0
        : 30.0;
    final color = isRecorded
        ? AppColors.mint
        : isCurrent
        ? AppColors.teal
        : AppColors.borderStrong;

    return MouseRegion(
      onEnter: (event) => onEnter(event.position),
      onHover: (event) => onHover(event.position),
      onExit: (event) => onExit(event.position),
      child: GestureDetector(
        key: ValueKey('calibration-target-$index'),
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: math.min(96.0, diameter),
                height: math.min(96.0, diameter),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
              ),
              if (progress > 0)
                SizedBox(
                  width: math.min(96.0, diameter) - 4,
                  height: math.min(96.0, diameter) - 4,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.2),
                  ),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: targetSize,
                height: targetSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: isRecorded
                    ? Icon(Icons.check, size: 22, color: AppColors.background)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
