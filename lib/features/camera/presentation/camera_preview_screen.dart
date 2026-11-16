import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dwell_action_card.dart';
import '../../../shared/widgets/dwell_back_button.dart';
import '../../../shared/widgets/figma_icon.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializationFuture;
  Future<void>? _disposalFuture;
  bool _initializing = true;
  bool _isAppActive = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposeCamera());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      if (controller == null || !controller.value.isInitialized) {
        _initializeCamera();
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isAppActive = false;
    }
    if (!_isAppActive && controller != null && controller.value.isInitialized) {
      unawaited(_disposeCamera());
    }
  }

  Future<void> _initializeCamera() {
    final pendingInitialization = _initializationFuture;
    if (pendingInitialization != null) return pendingInitialization;

    late final Future<void> initialization;
    initialization = _initializeCameraInternal().whenComplete(() {
      if (identical(_initializationFuture, initialization)) {
        _initializationFuture = null;
      }
    });
    _initializationFuture = initialization;
    return initialization;
  }

  Future<void> _startCalibration() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.pausePreview();
    } on CameraException catch (error) {
      debugPrint('Could not pause camera before calibration: ${error.code}');
    }
    if (!mounted) return;

    await context.pushNamed('calibration');

    if (!mounted || !identical(_controller, controller)) return;
    try {
      await controller.resumePreview();
    } on CameraException catch (error) {
      debugPrint('Could not resume camera after calibration: ${error.code}');
    }
  }

  Future<void> _initializeCameraInternal() async {
    if (!mounted) return;
    setState(() {
      _initializing = true;
      _errorMessage = null;
    });

    await _disposeCamera();
    await _disposalFuture;
    if (!mounted) return;

    CameraController? newController;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw const _CameraUiException(
          'مش لاقيين كاميرا على الجهاز. جرّب تشغيل التطبيق على موبايل أو افتحه من متصفح بيدعم الكاميرا.',
        );
      }

      CameraDescription? camera;
      for (final availableCamera in cameras) {
        if (availableCamera.lensDirection == CameraLensDirection.front) {
          camera = availableCamera;
          break;
        }
      }
      camera ??= cameras.first;

      newController = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await newController.initialize();

      if (!mounted || !_isAppActive) {
        await _safelyDispose(newController);
        if (mounted) setState(() => _initializing = false);
        return;
      }
      setState(() {
        _controller = newController;
        _initializing = false;
      });
    } on CameraException catch (error) {
      await _safelyDispose(newController);
      if (!mounted) return;
      setState(() {
        _controller = null;
        _initializing = false;
        _errorMessage = _cameraErrorMessage(error);
      });
    } catch (error) {
      await _safelyDispose(newController);
      if (!mounted) return;
      setState(() {
        _controller = null;
        _initializing = false;
        _errorMessage = error is _CameraUiException ? error.message : 'حصلت مشكلة وإحنا بنفتح الكاميرا. اتأكد إن التطبيق شغال على جهاز أو متصفح بيدعمها، وبعدها جرّب تاني.';
      });
    }
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'cameraPermission':
        return 'صلاحية الكاميرا مرفوضة. اسمح للتطبيق باستخدام الكاميرا من إعدادات الجهاز، وبعدها اضغط إعادة المحاولة.';
      case 'CameraAccessDeniedPermanently':
        return 'صلاحية الكاميرا مرفوضة بشكل دائم. افتح إعدادات التطبيق وفعّل صلاحية الكاميرا.';
      case 'NoCamera':
        return 'الجهاز ده مفيهوش كاميرا متاحة.';
      case 'CameraInUse':
        return 'الكاميرا مستخدمة دلوقتي من تطبيق تاني. اقفله وجرب تاني.';
      case 'AudioAccessDenied':
        return 'صلاحية الميكروفون مرفوضة. الشاشة دي مش محتاجة الميكروفون، راجع إعدادات الصلاحيات وجرب تاني.';
      default:
        return 'معرفناش نشغّل الكاميرا (${error.code}). اقفل أي تطبيق بيستخدمها وجرب تاني.';
    }
  }

  Future<void> _disposeCamera() {
    final controller = _controller;
    _controller = null;
    if (controller == null) return _disposalFuture ?? Future<void>.value();

    final disposal = _safelyDispose(controller);
    _disposalFuture = disposal;
    return disposal;
  }

  Future<void> _safelyDispose(CameraController? controller) async {
    if (controller == null) return;
    try {
      await controller.dispose();
    } on PlatformException catch (error) {
      // Some Android camera implementations throw while releasing a preview
      // surface that was never attached (for example, if the screen closes
      // during initialization). Keep cleanup failures from crashing the app.
      debugPrint('Camera cleanup failed (${error.code}): ${error.message}');
    } catch (error) {
      debugPrint('Camera cleanup failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(
        leading: const DwellBackButton(),
        title: Text(
          MediaQuery.sizeOf(context).width < 400
              ? 'معاينة الكاميرا'
              : 'خلّي وجهك واضحًا أمام الكاميرا',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          SizedBox(
            width: 48,
            height: 48,
            child: DwellActionCard(
              label: 'إعادة المحاولة',
              enabled: !_initializing,
              contentPadding: EdgeInsets.zero,
              onActivate: _initializeCamera,
              child: const Icon(Icons.refresh),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: DwellActionCard(
              label: 'المساعدة',
              contentPadding: EdgeInsets.zero,
              onActivate: () => context.pushNamed('help'),
              child: const FigmaIcon(AppAssets.help),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.maxWidth >= 600 &&
                  constraints.maxWidth > constraints.maxHeight;
              final preview = _CameraPreviewPanel(
                isReady: controller?.value.isInitialized ?? false,
                child: _buildPreview(controller),
              );
              final instructions = _cameraInstructions(context, controller);
              return wide
                  ? Row(
                      children: [
                        Expanded(flex: 7, child: preview),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(child: instructions),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(flex: 3, child: preview),
                        const SizedBox(height: 16),
                        Flexible(
                          flex: 2,
                          child: SingleChildScrollView(child: instructions),
                        ),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _cameraInstructions(
    BuildContext context,
    CameraController? controller,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'الخطوة ٢ من ٣',
        style: TextStyle(
          color: AppColors.teal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text('الوجه والعينان ظاهران', style: AppTextStyles.pageTitle),
      const SizedBox(height: 8),
      Text(
        'ضع الجهاز أمامك مباشرةً، وحافظ على الوضع المريح.',
        style: AppTextStyles.body,
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.greenSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.greenBorder),
        ),
        child: Row(
          children: [
            FigmaIcon(AppAssets.camera),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'تأكد يدويًا من ظهور الوجه والعينين. لا يوجد كشف وجه تلقائي.',
                style: TextStyle(color: AppColors.textMuted, height: 1.45),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      SizedBox(
        height: 64,
        child: DwellActionCard(
          label: 'ابدأ المعايرة',
          enabled: controller != null && controller.value.isInitialized,
          fillColor: AppColors.teal,
          borderRadius: 14,
          onActivate: _startCalibration,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_forward_rounded, color: AppColors.onPrimary),
                const SizedBox(width: 8),
                Text(
                  'ابدأ المعايرة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildPreview(CameraController? controller) {
    if (_initializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('بنجهّز الكاميرا...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, height: 1.6),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  height: 52,
                  child: DwellActionCard(
                    label: 'إعادة المحاولة',
                    borderColor: Colors.white70,
                    borderRadius: 12,
                    contentPadding: EdgeInsets.zero,
                    onActivate: _initializeCamera,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text(
          'الكاميرا مش جاهزة.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Let the camera plugin account for the sensor orientation when Android
    // rotates the app between portrait and landscape.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(360.0, constraints.maxWidth);
        final height = math.min(340.0, constraints.maxHeight);
        final ovalWidth = math.min(170.0, width * 0.8);
        final ovalHeight = math.min(210.0, height * 0.8);

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black,
                    child: Center(child: CameraPreview(controller)),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.72),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(48),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: ovalWidth,
                        height: ovalHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraPreviewPanel extends StatelessWidget {
  const _CameraPreviewPanel({required this.isReady, required this.child});

  final bool isReady;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0D171F),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .22),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF182A35), Color(0xFF0D171F)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: child),
            PositionedDirectional(
              top: 16,
              start: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .44),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isReady ? AppColors.mint : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isReady ? 'معاينة مباشرة' : 'معاينة الكاميرا',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const PositionedDirectional(
              bottom: 16,
              end: 16,
              child: Icon(
                Icons.lock_outline_rounded,
                color: Colors.white70,
                size: 20,
                semanticLabel: 'المعاينة لا تحفظ الصورة',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CameraUiException implements Exception {
  const _CameraUiException(this.message);
  final String message;
}
