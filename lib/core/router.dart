import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/chat_studio_screen.dart';
import '../features/home/home_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/editor/mask_painter_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/compliance/compliance_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/faq_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/models_screen.dart';
import '../features/settings/brand_screen.dart';
import '../features/billing/paywall_screen.dart';
import '../features/history/history_screen.dart';
import '../features/batch/batch_screen.dart';

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/chat-studio', builder: (_, __) => const ChatStudioScreen()),
    GoRoute(path: '/editor', builder: (_, s) => EditorScreen(imagePath: s.extra as String?)),
    GoRoute(path: '/mask', builder: (_, s) => MaskPainterScreen(imagePath: s.extra as String)),
    GoRoute(path: '/recipes', builder: (_, __) => const RecipesScreen()),
    GoRoute(path: '/compliance', builder: (_, __) => const ComplianceScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/faq', builder: (_, __) => const FAQScreen()),
    GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
    GoRoute(path: '/privacy', builder: (_, __) => const LegalScreen(type: 'privacy')),
    GoRoute(path: '/terms', builder: (_, __) => const LegalScreen(type: 'terms')),
    GoRoute(path: '/models', builder: (_, __) => const ModelsScreen()),
    GoRoute(path: '/brand', builder: (_, __) => const BrandScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/batch', builder: (_, __) => const BatchScreen()),
  ],
  errorBuilder: (c, s) => Scaffold(body: Center(child: FilledButton(onPressed: () => c.go('/home'), child: const Text('Go Home')))),
));
