import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/router.dart';
import 'core/motion/motion_tokens.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_preferences.dart';
import 'shared/widgets/dwell_action_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIChangeCallback((visible) async {
    if (visible) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  });
  runApp(const GazeLinkApp());
}

class GazeLinkApp extends StatefulWidget {
  const GazeLinkApp({super.key});

  @override
  State<GazeLinkApp> createState() => _GazeLinkAppState();
}

class _GazeLinkAppState extends State<GazeLinkApp>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _themeTransition;
  late Animation<double> _paletteAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppColors.setDarkMode(AppPreferences.darkMode.value);
    _themeTransition = AnimationController(
      vsync: this,
      duration: MotionTokens.durationLong,
    )..addListener(_updatePalette);
    _paletteAnimation = AlwaysStoppedAnimation(AppColors.darkBlend);
    AppPreferences.darkMode.addListener(_handleAppearanceChange);
  }

  bool get _prefersReducedMotion {
    final features = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures;
    return features.disableAnimations || features.accessibleNavigation;
  }

  void _handleAppearanceChange() {
    final target = AppPreferences.darkMode.value ? 1.0 : 0.0;
    if (_prefersReducedMotion) {
      _themeTransition.stop();
      AppColors.setAppearanceProgress(target);
      setState(() {});
      return;
    }

    _paletteAnimation =
        Tween<double>(begin: AppColors.darkBlend, end: target).animate(
          CurvedAnimation(
            parent: _themeTransition,
            curve: MotionTokens.curveEaseInOut,
          ),
        );
    _themeTransition.forward(from: 0);
  }

  void _updatePalette() {
    AppColors.setAppearanceProgress(_paletteAnimation.value);
    if (mounted) setState(() {});
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (_prefersReducedMotion) {
      _themeTransition.stop();
      AppColors.setDarkMode(AppPreferences.darkMode.value);
      setState(() {});
    }
  }

  @override
  void dispose() {
    AppPreferences.darkMode.removeListener(_handleAppearanceChange);
    _themeTransition
      ..removeListener(_updatePalette)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppPreferences.darkMode,
      builder: (context, darkMode, _) => MaterialApp.router(
        title: 'تواصل',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        themeAnimationDuration: Duration.zero,
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: AppPreferences.isResting,
          builder: (context, isResting, _) => ValueListenableBuilder<double>(
            valueListenable: AppPreferences.textScale,
            builder: (context, scale, _) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AbsorbPointer(
                      absorbing: isResting,
                      child: child ?? const SizedBox.shrink(),
                    ),
                    Positioned.fill(
                      child: _RestModeLayer(isResting: isResting),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        theme: AppTheme.build(darkMode: darkMode),
      ),
    );
  }
}

class _RestModeLayer extends StatefulWidget {
  const _RestModeLayer({required this.isResting});

  final bool isResting;

  @override
  State<_RestModeLayer> createState() => _RestModeLayerState();
}

class _RestModeLayerState extends State<_RestModeLayer> {
  late bool _blocksBackground = widget.isResting;

  @override
  void didUpdateWidget(_RestModeLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isResting) _blocksBackground = true;
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MotionTokens.prefersReducedMotion(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_blocksBackground) const AbsorbPointer(child: SizedBox.expand()),
        IgnorePointer(
          ignoring: !widget.isResting,
          child: AnimatedOpacity(
            opacity: widget.isResting ? 1 : 0,
            duration: reducedMotion
                ? Duration.zero
                : MotionTokens.durationMedium,
            curve: MotionTokens.curveEaseOut,
            onEnd: () {
              if (!widget.isResting && _blocksBackground && mounted) {
                setState(() => _blocksBackground = false);
              }
            },
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: .82),
              child: Center(
                child: SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 48)
                      .clamp(0, 360)
                      .toDouble(),
                  height: 112,
                  child: DwellActionCard(
                    label: 'متابعة التواصل',
                    allowDuringRestMode: true,
                    fillColor: AppColors.greenSurface,
                    borderColor: AppColors.greenBorder,
                    onActivate: () => AppPreferences.isResting.value = false,
                    child: Center(
                      child: Text(
                        'متابعة التواصل',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
