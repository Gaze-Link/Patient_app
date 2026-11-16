import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/app_preferences.dart';

/// Represents the interaction phase of a dwell target.
enum DwellStatus { idle, dwelling, activated, blocked }

/// Core, input-agnostic controller for dwell-based selection.
///
/// Decouples time-based gaze dwell logic from pointer/touch UI widgets,
/// allowing mouse hover, gaze coordinates, or synthetic input sources to drive
/// the same target detection, progress tracking, and activation pipeline.
class DwellController extends ChangeNotifier {
  DwellController({
    this.targetId,
    this.allowDuringRestMode = false,
    Duration? defaultDuration,
  }) : _customDuration = defaultDuration {
    AppPreferences.isResting.addListener(_handleRestModeChanged);
    if (targetId != null) {
      DwellCoordinator.instance.registerTarget(targetId!, this);
    }
  }

  final Object? targetId;
  final bool allowDuringRestMode;
  final Duration? _customDuration;

  Timer? _tickTimer;
  Timer? _activationTimer;
  Stopwatch? _stopwatch;

  double _progress = 0.0;
  bool _isActivated = false;
  bool _isEnabled = true;
  VoidCallback? _currentCallback;
  Duration? _activeDuration;

  /// Normalized progress from 0.0 (idle) to 1.0 (activated).
  double get progress => _progress;

  /// Whether the dwell countdown is actively running.
  bool get isDwelling => _tickTimer != null && !_isActivated;

  /// Whether the target has completed its dwell and been activated.
  /// Remains true while the pointer/gaze stays inside the target to prevent re-triggering.
  bool get isActivated => _isActivated;

  /// Whether interaction is enabled.
  bool get isEnabled => _isEnabled;

  set isEnabled(bool value) {
    if (_isEnabled == value) return;
    _isEnabled = value;
    if (!_isEnabled) {
      final hadActiveDwell = _tickTimer != null || _isActivated;
      cancelDwell();
      if (!hadActiveDwell) notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// Whether interaction is blocked (disabled or during rest mode).
  bool get isBlocked =>
      !_isEnabled || (AppPreferences.isResting.value && !allowDuringRestMode);

  Duration get configuredDuration =>
      _customDuration ??
      Duration(milliseconds: AppPreferences.dwellMilliseconds.value);

  void _handleRestModeChanged() {
    if (AppPreferences.isResting.value && !allowDuringRestMode) {
      cancelDwell();
    }
    notifyListeners();
  }

  /// Starts the dwell countdown for this target.
  ///
  /// Automatically cancels any other active dwell target via [DwellCoordinator].
  void startDwell({required VoidCallback onActivate, Duration? duration}) {
    if (isBlocked || _isActivated) return;

    // Register with central coordinator to cancel any other target
    DwellCoordinator.instance.notifyDwellStarted(this);

    _clearTimers();
    _currentCallback = onActivate;
    _activeDuration = duration ?? configuredDuration;
    _progress = 0.0;
    _isActivated = false;

    final targetDuration = _activeDuration!;
    _stopwatch = Stopwatch()..start();

    const tick = Duration(milliseconds: 30);
    _tickTimer = Timer.periodic(tick, (timer) {
      if (isBlocked) {
        cancelDwell();
        return;
      }
      final elapsedMicros = _stopwatch?.elapsedMicroseconds ?? 0;
      final totalMicros = targetDuration.inMicroseconds;
      if (totalMicros <= 0) {
        _handleActivation();
        return;
      }
      final nextProgress = (elapsedMicros / totalMicros).clamp(0.0, 1.0);
      _progress = nextProgress;
      notifyListeners();
    });

    _activationTimer = Timer(targetDuration, () {
      if (isBlocked) {
        cancelDwell();
        return;
      }
      _handleActivation();
    });

    notifyListeners();
  }

  void _handleActivation() {
    _clearTimers();
    _isActivated = true;
    _progress = 1.0;
    DwellCoordinator.instance.notifyDwellEnded(this);
    notifyListeners();

    final callback = _currentCallback;
    _currentCallback = null;
    callback?.call();
  }

  /// Cancels the dwell countdown and resets progress to zero.
  void cancelDwell() {
    final hadProgress = _progress > 0.0 || _isActivated || _tickTimer != null;
    _clearTimers();
    _isActivated = false;
    _currentCallback = null;
    _progress = 0.0;

    DwellCoordinator.instance.notifyDwellEnded(this);

    if (hadProgress) {
      notifyListeners();
    }
  }

  /// Activates the target immediately (e.g. on direct tap or external trigger).
  void triggerImmediate({required VoidCallback onActivate}) {
    if (isBlocked) return;
    cancelDwell();
    _isActivated = true;
    _progress = 1.0;
    notifyListeners();
    onActivate();
  }

  void _clearTimers() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _activationTimer?.cancel();
    _activationTimer = null;
    _stopwatch?.stop();
    _stopwatch = null;
  }

  @override
  void dispose() {
    _clearTimers();
    _currentCallback = null;
    AppPreferences.isResting.removeListener(_handleRestModeChanged);
    DwellCoordinator.instance.unregister(this);
    super.dispose();
  }
}

/// Central coordinator ensuring only one dwell target runs at any time
/// across the entire application, and providing an integration surface
/// for future gaze coordinate hit-testing.
///
/// Maintains strong references to registered controllers in a standard Map,
/// requiring explicit unregistration via [unregisterTarget] or [unregister]
/// when controllers or target widgets are disposed.
class DwellCoordinator {
  DwellCoordinator._();
  static final DwellCoordinator instance = DwellCoordinator._();

  DwellController? _activeController;
  final Map<Object, DwellController> _targetRegistry = {};

  DwellController? get activeController => _activeController;

  /// Registers a target with an identifier for coordinate-based resolution.
  void registerTarget(Object targetId, DwellController controller) {
    _targetRegistry[targetId] = controller;
  }

  /// Unregisters a target identifier.
  void unregisterTarget(Object targetId) {
    _targetRegistry.remove(targetId);
  }

  /// Called when a controller begins dwell, cancelling any previous one.
  void notifyDwellStarted(DwellController controller) {
    if (_activeController != null &&
        !identical(_activeController, controller)) {
      _activeController?.cancelDwell();
    }
    _activeController = controller;
  }

  /// Called when a controller cancels or finishes.
  void notifyDwellEnded(DwellController controller) {
    if (identical(_activeController, controller)) {
      _activeController = null;
    }
  }

  /// Cleans up references when a controller is disposed.
  void unregister(DwellController controller) {
    if (identical(_activeController, controller)) {
      _activeController = null;
    }
    if (controller.targetId != null) {
      if (identical(_targetRegistry[controller.targetId], controller)) {
        _targetRegistry.remove(controller.targetId);
      }
    }
  }

  /// Gaze coordinate entry point for future eye-tracking providers.
  ///
  /// Resolves the target at [targetId] and triggers dwell without requiring
  /// pointer/mouse event simulation.
  void gazeEnter(
    Object targetId, {
    required VoidCallback onActivate,
    Duration? duration,
  }) {
    final controller = _targetRegistry[targetId];
    controller?.startDwell(onActivate: onActivate, duration: duration);
  }

  /// Gaze coordinate exit point for future eye-tracking providers.
  void gazeExit(Object targetId) {
    final controller = _targetRegistry[targetId];
    controller?.cancelDwell();
  }

  /// Cancels all active dwell timers application-wide.
  void cancelAll() {
    _activeController?.cancelDwell();
    _activeController = null;
  }
}
