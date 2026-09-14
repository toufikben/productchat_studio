import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/chat_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/batch/batch_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/brand_screen.dart';
import '../features/history/history_screen.dart';
import '../features/billing/paywall_screen.dart';

final routerProvider = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(
          path: '/editor',
          builder: (_, state) =>
              EditorScreen(imagePath: state.uri.queryParameters['imagePath'])),
      GoRoute(path: '/batch', builder: (_, __) => const BatchScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/brand', builder: (_, __) => const BrandScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/legal', builder: (_, __) => const LegalScreen()),
      GoRoute(path: '/credits', builder: (_, __) => const PaywallScreen())
    ],
    errorBuilder: (_, __) =>
        const Scaffold(body: Center(child: Text('Page not found'))));
