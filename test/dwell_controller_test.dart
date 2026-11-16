import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gaze_app/core/dwell/dwell_controller.dart';
import 'package:gaze_app/core/utils/app_preferences.dart';
import 'package:gaze_app/shared/widgets/dwell_action_card.dart';

void main() {
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppPreferences.dwellMilliseconds.value = 1500;
    AppPreferences.isResting.value = false;
    DwellCoordinator.instance.cancelAll();
  });

  group('DwellController Unit Tests (Input-Agnostic)', () {
    test('entering a target starts the timer and updates progress', () {
      final controller = DwellController(
        defaultDuration: const Duration(seconds: 1),
      );
      expect(controller.progress, 0.0);
      expect(controller.isDwelling, isFalse);

      var activated = false;
      controller.startDwell(onActivate: () => activated = true);

      expect(controller.isDwelling, isTrue);
      expect(activated, isFalse);

      controller.dispose();
    });

    testWidgets(
      'completing 1.5 seconds activates target automatically without click',
      (WidgetTester tester) async {
        final controller = DwellController();
        expect(
          controller.configuredDuration,
          const Duration(milliseconds: 1500),
        );

        var activations = 0;
        controller.startDwell(onActivate: () => activations++);

        // Verify NOT called before 1500ms
        await tester.pump(const Duration(milliseconds: 1499));
        expect(activations, 0);
        expect(controller.isDwelling, isTrue);
        expect(controller.isActivated, isFalse);

        // Verify IS called after the full 1500ms (exactly once)
        await tester.pump(const Duration(milliseconds: 1));
        expect(activations, 1);
        expect(controller.isDwelling, isFalse);
        expect(controller.isActivated, isTrue);
        expect(controller.progress, 1.0);
        expect(DwellCoordinator.instance.activeController, isNull);

        // Verify repeated activation is prevented while remaining in target
        await tester.pump(const Duration(seconds: 3));
        expect(activations, 1);

        controller.dispose();
      },
    );

    test('leaving before completion cancels and resets progress', () {
      final controller = DwellController(
        defaultDuration: const Duration(milliseconds: 1500),
      );
      controller.startDwell(onActivate: () {});
      expect(controller.isDwelling, isTrue);

      controller.cancelDwell();
      expect(controller.isDwelling, isFalse);
      expect(controller.progress, 0.0);
      expect(controller.isActivated, isFalse);

      controller.dispose();
    });

    test('moving to another target resets the previous target via DwellCoordinator', () {
      final controller1 = DwellController(targetId: 'target_1');
      final controller2 = DwellController(targetId: 'target_2');

      var activated1 = 0;
      var activated2 = 0;

      controller1.startDwell(onActivate: () => activated1++);
      expect(controller1.isDwelling, isTrue);
      expect(DwellCoordinator.instance.activeController, controller1);

      // Start dwell on controller 2
      controller2.startDwell(onActivate: () => activated2++);

      // Controller 1 must be cancelled and reset
      expect(controller1.isDwelling, isFalse);
      expect(controller1.progress, 0.0);
      expect(controller2.isDwelling, isTrue);
      expect(DwellCoordinator.instance.activeController, controller2);

      controller1.dispose();
      controller2.dispose();
    });

    test('disposing controller cancels active timers safely', () {
      final controller = DwellController(
        defaultDuration: const Duration(seconds: 1),
      );
      controller.startDwell(onActivate: () {});
      expect(controller.isDwelling, isTrue);

      controller.dispose();
      expect(controller.isDwelling, isFalse);
      expect(DwellCoordinator.instance.activeController, isNull);
    });

    test('DwellCoordinator allows future gaze coordinates to enter and exit targets', () {
      final controller = DwellController(targetId: 'gaze_target_x');

      var activated = false;
      DwellCoordinator.instance.gazeEnter(
        'gaze_target_x',
        onActivate: () => activated = true,
      );

      expect(controller.isDwelling, isTrue);

      DwellCoordinator.instance.gazeExit('gaze_target_x');
      expect(controller.isDwelling, isFalse);
      expect(controller.progress, 0.0);
      expect(activated, isFalse);

      controller.dispose();
    });

    test('disposing a replaced target does not unregister its replacement', () {
      final previous = DwellController(targetId: 'shared_gaze_target');
      final current = DwellController(targetId: 'shared_gaze_target');
      previous.dispose();

      DwellCoordinator.instance.gazeEnter(
        'shared_gaze_target',
        onActivate: () {},
      );

      expect(current.isDwelling, isTrue);
      current.dispose();
    });
  });

  group('DwellActionCard Widget Tests (Timed Simulation)', () {
    testWidgets('completing exact 1.5 seconds activates card automatically', (
      WidgetTester tester,
    ) async {
      AppPreferences.dwellMilliseconds.value = 1500;
      var activations = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DwellActionCard(
                label: 'هدف تجريبي',
                onActivate: () => activations++,
                child: const Text('هدف تجريبي'),
              ),
            ),
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('هدف تجريبي')));
      await tester.pump();

      // At 1490ms: not activated
      await tester.pump(const Duration(milliseconds: 1490));
      expect(activations, 0);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // At 1500ms (+10ms): activated automatically without click
      await tester.pump(const Duration(milliseconds: 10));
      expect(activations, 1);

      // Moving mouse inside the same target does NOT reactivate (Requirement 6)
      await mouse.moveBy(const Offset(2, 2));
      await tester.pump(const Duration(milliseconds: 2000));
      expect(activations, 1);

      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'leaving target before 1.5s cancels dwell and resets indicator',
      (WidgetTester tester) async {
        AppPreferences.dwellMilliseconds.value = 1500;
        var activations = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  DwellActionCard(
                    label: 'بطاقة ١',
                    onActivate: () => activations++,
                    child: const Text('بطاقة ١'),
                  ),
                  const SizedBox(height: 100),
                  const Text('منطقة فارغة'),
                ],
              ),
            ),
          ),
        );

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.text('بطاقة ١')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        expect(activations, 0);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Move away to empty area
        await mouse.moveTo(tester.getCenter(find.text('منطقة فارغة')));
        await tester.pump();

        // Indicator must disappear and timer cancelled
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await tester.pump(const Duration(milliseconds: 1000));
        expect(activations, 0);

        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('moving directly between two cards resets the first card', (
      WidgetTester tester,
    ) async {
      AppPreferences.dwellMilliseconds.value = 1500;
      var card1Activations = 0;
      var card2Activations = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DwellActionCard(
                  label: 'بطاقة أ',
                  onActivate: () => card1Activations++,
                  child: const Text('بطاقة أ'),
                ),
                DwellActionCard(
                  label: 'بطاقة ب',
                  onActivate: () => card2Activations++,
                  child: const Text('بطاقة ب'),
                ),
              ],
            ),
          ),
        ),
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);

      // Enter card A
      await mouse.moveTo(tester.getCenter(find.text('بطاقة أ')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(card1Activations, 0);

      // Move directly to card B
      await mouse.moveTo(tester.getCenter(find.text('بطاقة ب')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));

      // Card B should activate; Card A should not have activated
      expect(card1Activations, 0);
      expect(card2Activations, 1);

      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
