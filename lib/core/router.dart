import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/chat_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/batch/batch_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/faq_screen.dart';
import '../features/settings/models_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/compliance/compliance_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/brand_screen.dart';
import '../features/history/history_screen.dart';
import '../features/billing/paywall_screen.dart';

final routerProvider = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
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
      GoRoute(path: '/faq', builder: (_, __) => const FAQScreen()),
      GoRoute(path: '/models', builder: (_, __) => const ModelsScreen()),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
      GoRoute(path: '/recipes', builder: (_, __) => const RecipesScreen()),
      GoRoute(path: '/compliance', builder: (_, __) => const ComplianceScreen()),
      GoRoute(path: '/credits', builder: (_, __) => const PaywallScreen())
    ],
    errorBuilder: (_, __) =>
        const Scaffold(body: Center(child: Text('Page not found'))));
