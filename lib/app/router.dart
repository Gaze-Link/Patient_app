import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/motion_tokens.dart';
import '../features/calibration/presentation/calibration_screen.dart';
import '../features/camera/presentation/camera_preview_screen.dart';
import '../features/communication/presentation/communication_screen.dart';
import '../features/communication/presentation/phrase_confirmation_screen.dart';
import '../features/communication/presentation/sentence_builder_screen.dart';
import '../features/help/presentation/emergency_screen.dart';
import '../features/help/presentation/help_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/setup/presentation/setup_screen.dart';
import '../features/setup/presentation/patient_home_screen.dart';

CustomTransitionPage<void> _buildFadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: MotionTokens.durationShort,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MotionTokens.prefersReducedMotion(context)) {
        return child;
      }
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: MotionTokens.curveEaseOut,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const SetupScreen()),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const PatientHomeScreen()),
    ),
    GoRoute(
      path: '/categories',
      name: 'categories',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const PatientHomeScreen(showCategories: true)),
    ),
    GoRoute(
      path: '/camera',
      name: 'camera',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const CameraScreen()),
    ),
    GoRoute(
      path: '/calibration',
      name: 'calibration',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const CalibrationScreen()),
    ),
    GoRoute(
      path: '/communication',
      name: 'communication',
      pageBuilder: (context, state) => _buildFadePage(
        state,
        CommunicationScreen(category: state.uri.queryParameters['category']),
      ),
    ),
    GoRoute(
      path: '/emergency',
      name: 'emergency',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const EmergencyScreen()),
    ),
    GoRoute(
      path: '/confirmation',
      name: 'confirmation',
      pageBuilder: (context, state) => _buildFadePage(
        state,
        PhraseConfirmationScreen(
          phrase: state.uri.queryParameters['phrase'] ?? '',
          category: state.uri.queryParameters['category'],
        ),
      ),
    ),
    GoRoute(
      path: '/composer',
      name: 'composer',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const SentenceBuilderScreen()),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: '/help',
      name: 'help',
      pageBuilder: (context, state) =>
          _buildFadePage(state, const HelpScreen()),
    ),
  ],
);
