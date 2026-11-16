import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gaze_app/main.dart';
import 'package:gaze_app/app/router.dart';
import 'package:gaze_app/features/calibration/presentation/calibration_screen.dart';
import 'package:gaze_app/features/camera/presentation/camera_preview_screen.dart';
import 'package:gaze_app/features/communication/presentation/communication_screen.dart';
import 'package:gaze_app/features/communication/presentation/phrase_confirmation_screen.dart';
import 'package:gaze_app/features/communication/presentation/sentence_builder_screen.dart';
import 'package:gaze_app/features/help/presentation/emergency_screen.dart';
import 'package:gaze_app/features/help/presentation/help_screen.dart';
import 'package:gaze_app/features/settings/presentation/settings_screen.dart';
import 'package:gaze_app/features/setup/presentation/patient_home_screen.dart';
import 'package:gaze_app/features/setup/presentation/setup_screen.dart';
import 'package:gaze_app/core/utils/app_preferences.dart';
import 'package:gaze_app/core/theme/app_colors.dart';
import 'package:gaze_app/core/motion/speaking_waveform.dart';
import 'package:gaze_app/shared/widgets/dwell_action_card.dart';
import 'package:gaze_app/features/communication/presentation/widgets/communication_phrase_tile.dart';

void main() {
  testWidgets('shared dwell card activates after the configured real dwell', (
    WidgetTester tester,
  ) async {
    AppPreferences.dwellMilliseconds.value = 750;
    AppPreferences.isResting.value = false;
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 120,
            child: DwellActionCard(
              label: 'اختيار تجريبي',
              contentPadding: EdgeInsets.zero,
              onActivate: () => activations++,
              child: const Center(child: Text('اختيار تجريبي')),
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('اختيار تجريبي')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 749));
    expect(activations, 0);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(activations, 1);

    await mouse.removePointer();
    AppPreferences.dwellMilliseconds.value = 1500;
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rest mode blocks all cards except the resume target', (
    WidgetTester tester,
  ) async {
    AppPreferences.dwellMilliseconds.value = 500;
    AppPreferences.isResting.value = true;
    var blockedActivations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                DwellActionCard(
                  label: 'اختيار',
                  onActivate: () => blockedActivations++,
                  child: const Text('اختيار'),
                ),
                DwellActionCard(
                  label: 'متابعة',
                  allowDuringRestMode: true,
                  onActivate: () => AppPreferences.isResting.value = false,
                  child: const Text('متابعة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('اختيار')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(blockedActivations, 0);

    await mouse.moveTo(tester.getCenter(find.text('متابعة')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(AppPreferences.isResting.value, isFalse);

    await mouse.removePointer();
    AppPreferences.dwellMilliseconds.value = 1500;
    AppPreferences.isResting.value = false;
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('appearance switch updates the theme across app screens', (
    WidgetTester tester,
  ) async {
    AppPreferences.darkMode.value = true;
    appRouter.go('/');
    await tester.pumpWidget(const GazeLinkApp());
    await tester.pumpAndSettle();

    var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      const Color(0xFF101820),
    );

    appRouter.go('/settings');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme?.brightness, Brightness.light);
    appRouter.go('/');
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      const Color(0xFFF5F8F8),
    );
    AppPreferences.darkMode.value = true;
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('appearance palette transitions smoothly between themes', (
    WidgetTester tester,
  ) async {
    AppPreferences.darkMode.value = true;
    await tester.pumpWidget(const GazeLinkApp());
    await tester.pumpAndSettle();

    AppPreferences.darkMode.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));

    expect(AppColors.darkBlend, greaterThan(0));
    expect(AppColors.darkBlend, lessThan(1));
    await tester.pumpAndSettle();
    expect(AppColors.darkBlend, 0);

    AppPreferences.darkMode.value = true;
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('speaking waveform fits its measured width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SpeakingWaveform(isSpeaking: true))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome and home layouts fit common compact and tablet sizes', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sizes = [
      const Size(320, 568),
      const Size(390, 844),
      const Size(834, 1194),
      const Size(1280, 800),
      const Size(844, 390),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SetupScreen()),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const PatientHomeScreen(),
          ),
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) =>
                const PatientHomeScreen(showCategories: true),
          ),
          GoRoute(
            path: '/composer',
            name: 'composer',
            builder: (context, state) => const SentenceBuilderScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/help',
            name: 'help',
            builder: (context, state) => const HelpScreen(),
          ),
          GoRoute(
            path: '/camera',
            name: 'camera',
            builder: (context, state) => const CameraScreen(),
          ),
          GoRoute(
            path: '/communication',
            name: 'communication',
            builder: (context, state) => CommunicationScreen(
              category: state.uri.queryParameters['category'],
            ),
          ),
          GoRoute(
            path: '/emergency',
            name: 'emergency',
            builder: (context, state) => const EmergencyScreen(),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'welcome at $size');

      router.go('/dashboard');
      await tester.pumpAndSettle();
      final layoutException = tester.takeException();
      expect(layoutException, isNull, reason: 'home at $size');

      router.go('/categories');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'categories at $size');

      for (final category in ['needs', 'health', 'feelings']) {
        router.go('/communication?category=$category');
        await tester.pumpAndSettle();
        expect(find.text('مساعدة عاجلة'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '$category communication screen at $size',
        );
        if (category == 'needs') {
          await tester.tap(find.text('مساعدة عاجلة'));
          await tester.pumpAndSettle();
          expect(find.text('مساعدة عاجلة'), findsOneWidget);
          router.go('/communication?category=$category');
          await tester.pumpAndSettle();
        }
      }

      for (final route in ['/composer', '/settings', '/help', '/emergency']) {
        router.go(route);
        await tester.pumpAndSettle();
        final screenError = tester.takeException();
        expect(screenError, isNull, reason: '$route at $size: $screenError');
      }

      router.go('/camera');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final cameraError = tester.takeException();
      expect(cameraError, isNull, reason: 'camera at $size: $cameraError');

      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });

  testWidgets('welcome screen follows the Arabic Figma onboarding', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GazeLinkApp());

    expect(find.text('ابدأ'), findsOneWidget);
    expect(find.text('أهلاً بك في تواصل'), findsOneWidget);
    expect(find.text('كلامك مهم، وصوتك يستحق أن يُسمع'), findsOneWidget);
  });

  testWidgets('calibration records nine simulated targets before continuing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CalibrationScreen()));

    expect(find.text('ثبّت عينك على النقطة 1 من ٩'), findsOneWidget);
    final continueButton = find.byWidgetPredicate(
      (widget) => widget is DwellActionCard && widget.label == 'ابدأ التواصل',
    );
    expect(tester.widget<DwellActionCard>(continueButton).enabled, isFalse);

    for (var index = 0; index < 9; index++) {
      await tester.tap(find.byKey(ValueKey('calibration-target-$index')));
      await tester.pump();
    }

    expect(find.text('اتسجلت ٩ من ٩ نقاط (محاكاة)'), findsOneWidget);
    expect(tester.widget<DwellActionCard>(continueButton).enabled, isTrue);
  });

  testWidgets('calibration continues to the dashboard in either orientation', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final router = GoRouter(
        initialLocation: '/calibration',
        routes: [
          GoRoute(
            path: '/calibration',
            name: 'calibration',
            builder: (context, state) => const CalibrationScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('واصلت إلى الرئيسية'))),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      for (var index = 0; index < 9; index++) {
        await tester.tap(find.byKey(ValueKey('calibration-target-$index')));
        await tester.pumpAndSettle();
      }
      expect(find.text('اتسجلت ٩ من ٩ نقاط (محاكاة)'), findsOneWidget);
      await tester.tap(find.text('ابدأ التواصل'));
      await tester.pumpAndSettle();

      expect(find.text('واصلت إلى الرئيسية'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
    }
  });

  testWidgets('mouse dwell advances a calibration target', (
    WidgetTester tester,
  ) async {
    final previousDwell = AppPreferences.dwellMilliseconds.value;
    AppPreferences.dwellMilliseconds.value = 900;
    addTearDown(() => AppPreferences.dwellMilliseconds.value = previousDwell);
    await tester.pumpWidget(const MaterialApp(home: CalibrationScreen()));

    final target = find.byKey(const ValueKey('calibration-target-0'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(find.text('ثبّت عينك على النقطة 2 من ٩'), findsOneWidget);
    await mouse.removePointer();
  });

  testWidgets('mouse dwell selects and speaks once after 1.5 seconds', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    _mockTts(calls);

    await tester.pumpWidget(const MaterialApp(home: CommunicationScreen()));
    await tester.pumpAndSettle();

    final target = find.text('أحتاج مساعدة');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('الاختيار المحاكى: أحتاج مساعدة'), findsNothing);

    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();
    expect(find.text('الاختيار المحاكى: أحتاج مساعدة'), findsOneWidget);
    expect(
      calls
          .where((call) => call.method == 'speak')
          .map((call) => call.arguments),
      ['أحتاج مساعدة'],
    );

    await tester.pump(const Duration(seconds: 3));
    expect(calls.where((call) => call.method == 'speak'), hasLength(1));
    await mouse.removePointer();
  });

  testWidgets('tapping an option selects and speaks immediately', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    _mockTts(calls);

    await tester.pumpWidget(const MaterialApp(home: CommunicationScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحتاج مساعدة'));
    await tester.pump();

    expect(find.text('الاختيار المحاكى: أحتاج مساعدة'), findsOneWidget);
    expect(
      calls.where((call) => call.method == 'speak').single.arguments,
      'أحتاج مساعدة',
    );
  });

  testWidgets('communication speaks a routed phrase only on confirmation', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    _mockTts(calls);
    final router = GoRouter(
      initialLocation: '/communication?category=communication',
      routes: [
        GoRoute(
          path: '/communication',
          builder: (context, state) => CommunicationScreen(
            category: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(
          path: '/confirmation',
          name: 'confirmation',
          builder: (context, state) => PhraseConfirmationScreen(
            phrase: state.uri.queryParameters['phrase'] ?? '',
            category: state.uri.queryParameters['category'],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحتاج مساعدة'));
    await tester.pumpAndSettle();

    expect(find.byType(PhraseConfirmationScreen), findsOneWidget);
    expect(calls.where((call) => call.method == 'speak'), hasLength(1));
    expect(
      calls.where((call) => call.method == 'speak').single.arguments,
      'أحتاج مساعدة',
    );
  });

  testWidgets('communication category tabs clear the previous selection', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/communication?category=needs',
      routes: [
        GoRoute(
          path: '/communication',
          name: 'communication',
          builder: (context, state) => CommunicationScreen(
            category: state.uri.queryParameters['category'],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('صحتي وألمي'));
    await tester.pumpAndSettle();

    expect(find.text('كيف تشعر؟'), findsOneWidget);
    expect(find.text('عايز أشرب'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected phrase highlight moves only after a new selection', (
    WidgetTester tester,
  ) async {
    _mockTts([]);
    await tester.pumpWidget(const MaterialApp(home: CommunicationScreen()));
    await tester.pumpAndSettle();

    final firstPhrase = find.byWidgetPredicate(
      (widget) =>
          widget is CommunicationPhraseTile &&
          widget.option.label == 'أحتاج مساعدة',
    );
    final secondPhrase = find.byWidgetPredicate(
      (widget) =>
          widget is CommunicationPhraseTile && widget.option.label == 'نعم',
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(firstPhrase));
    await tester.pump();
    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isHighlighted,
      isFalse,
    );
    await tester.tap(firstPhrase);
    await tester.pump();
    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isHighlighted,
      isTrue,
    );

    await mouse.moveTo(tester.getCenter(secondPhrase));
    await tester.pump();
    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isHighlighted,
      isTrue,
    );
    expect(
      tester.widget<CommunicationPhraseTile>(secondPhrase).isHighlighted,
      isFalse,
    );
    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isSelected,
      isTrue,
    );

    await tester.tap(secondPhrase);
    await tester.pump();
    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isHighlighted,
      isFalse,
    );
    expect(
      tester.widget<CommunicationPhraseTile>(secondPhrase).isHighlighted,
      isTrue,
    );
    expect(
      tester.widget<CommunicationPhraseTile>(secondPhrase).isSelected,
      isTrue,
    );
    await mouse.removePointer();
  });

  testWidgets('selected highlight moves after returning from confirmation', (
    WidgetTester tester,
  ) async {
    _mockTts([]);
    final router = GoRouter(
      initialLocation: '/communication?category=communication',
      routes: [
        GoRoute(
          path: '/communication',
          builder: (context, state) => CommunicationScreen(
            category: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(
          path: '/confirmation',
          name: 'confirmation',
          builder: (context, state) => PhraseConfirmationScreen(
            phrase: state.uri.queryParameters['phrase'] ?? '',
            category: state.uri.queryParameters['category'],
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أحتاج مساعدة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    final firstPhrase = find.byWidgetPredicate(
      (widget) =>
          widget is CommunicationPhraseTile &&
          widget.option.label == 'أحتاج مساعدة',
    );
    final secondPhrase = find.byWidgetPredicate(
      (widget) =>
          widget is CommunicationPhraseTile && widget.option.label == 'نعم',
    );
    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isHighlighted,
      isTrue,
    );

    await tester.tap(find.text('نعم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CommunicationPhraseTile>(firstPhrase).isHighlighted,
      isFalse,
    );
    expect(
      tester.widget<CommunicationPhraseTile>(secondPhrase).isHighlighted,
      isTrue,
    );
  });

  testWidgets('larger calibration checks fit phone and tablet sizes', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(key: ValueKey(size), home: const CalibrationScreen()),
      );
      await tester.pumpAndSettle();

      for (var index = 0; index < 9; index++) {
        await tester.tap(find.byKey(ValueKey('calibration-target-$index')));
        await tester.pump();
      }

      expect(find.text('تم تأكيد النتيجة'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'calibration at $size');
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('phrase confirmation fits a 320 pixel viewport', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    _mockTts(calls);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: PhraseConfirmationScreen(
          phrase: 'أحتاج إلى مساعدة الآن',
          category: 'needs',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('العبارة جاهزة'), findsOneWidget);
  });

  testWidgets('leaving a target interrupts dwell without speaking', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    _mockTts(calls);

    await tester.pumpWidget(const MaterialApp(home: CommunicationScreen()));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('أحتاج مساعدة')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await mouse.moveTo(const Offset(4, 4));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('الاختيار المحاكى: أحتاج مساعدة'), findsNothing);
    expect(calls.where((call) => call.method == 'speak'), isEmpty);
    await mouse.removePointer();
  });

  testWidgets('changing target restarts the dwell timer', (
    WidgetTester tester,
  ) async {
    final calls = <MethodCall>[];
    _mockTts(calls);

    await tester.pumpWidget(const MaterialApp(home: CommunicationScreen()));
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('أحتاج مساعدة')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    await mouse.moveTo(tester.getCenter(find.text('نعم')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1499));
    expect(find.text('الاختيار المحاكى: نعم'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('الاختيار المحاكى: نعم'), findsOneWidget);
    expect(calls.where((call) => call.method == 'speak'), hasLength(1));
    expect(
      calls.where((call) => call.method == 'speak').single.arguments,
      'نعم',
    );
    await mouse.removePointer();
  });
}

void _mockTts(List<MethodCall> calls) {
  const channel = MethodChannel('flutter_tts');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    calls.add(call);
    if (call.method == 'getLanguages') return ['ar-EG'];
    return 1;
  });
}
