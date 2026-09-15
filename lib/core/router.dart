import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/chat_studio_screen.dart';
import '../features/chat/chat_history_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/editor/mask_painter_screen.dart';
import '../features/editor/presets_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/compliance/compliance_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/faq_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/models_screen.dart';
import '../features/settings/brand_screen.dart';
import '../features/settings/developer_screen.dart';
import '../features/settings/marketplace_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/feedback_screen.dart';
import '../features/settings/update_screen.dart';
import '../features/settings/favorites_screen.dart';
import '../features/settings/referral_screen.dart';
import '../features/settings/analytics_screen.dart';
import '../features/settings/roadmap_screen.dart';
import '../features/settings/voice_settings_screen.dart';
import '../features/settings/voice_presets_screen.dart';
import '../features/chat/voice_search_screen.dart';
import '../features/billing/paywall_screen.dart';
import '../features/billing/subscription_status_screen.dart';
import '../features/billing/promo_code_screen.dart';
import '../features/billing/refund_policy_screen.dart';
import '../features/history/history_screen.dart';
import '../features/batch/batch_screen.dart';
import '../features/advanced/ai_description_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // ─── Splash & Onboarding ───
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // ─── Home (with Floating Nav) ───
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

      // ─── Chat ───
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/chat-studio', builder: (_, __) => const ChatStudioScreen()),
      GoRoute(path: '/chat-history', builder: (_, __) => const ChatHistoryScreen()),

      // ─── Editor ───
      GoRoute(
        path: '/editor',
        builder: (_, s) => EditorScreen(imagePath: s.extra as String?),
      ),
      GoRoute(
        path: '/mask-painter',
        builder: (_, s) => MaskPainterScreen(imagePath: s.extra as String),
      ),
      GoRoute(path: '/presets', builder: (_, __) => const PresetsScreen()),

      // ─── Advanced ───
      GoRoute(
        path: '/ai-description',
        builder: (_, s) => AIDescriptionScreen(imagePath: s.extra as String),
      ),

      // ─── Features ───
      GoRoute(path: '/recipes', builder: (_, __) => const RecipesScreen()),
      GoRoute(path: '/compliance', builder: (_, __) => const ComplianceScreen()),
      GoRoute(path: '/batch', builder: (_, __) => const BatchScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),

      // ─── Billing ───
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
      GoRoute(path: '/subscription-status', builder: (_, __) => const SubscriptionStatusScreen()),
      GoRoute(path: '/promo-code', builder: (_, __) => const PromoCodeScreen()),
      GoRoute(path: '/refund-policy', builder: (_, __) => const RefundPolicyScreen()),

      // ─── Settings ───
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/models', builder: (_, __) => const ModelsScreen()),
      GoRoute(path: '/brand', builder: (_, __) => const BrandScreen()),
      GoRoute(path: '/developer', builder: (_, __) => const DeveloperScreen()),
      GoRoute(path: '/marketplace', builder: (_, __) => const MarketplaceScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/feedback', builder: (_, __) => const FeedbackScreen()),
      GoRoute(path: '/update', builder: (_, __) => const UpdateScreen()),
      GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/referral', builder: (_, __) => const ReferralScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(path: '/roadmap', builder: (_, __) => const RoadmapScreen()),
      GoRoute(path: '/voice-settings', builder: (_, __) => const VoiceSettingsScreen()),
      GoRoute(path: '/voice-presets', builder: (_, __) => const VoicePresetsScreen()),
      GoRoute(path: '/voice-search', builder: (_, __) => const VoiceSearchScreen()),

      // ─── Support ───
      GoRoute(path: '/faq', builder: (_, __) => const FAQScreen()),
      GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),

      // ─── Legal ───
      GoRoute(
        path: '/privacy',
        builder: (_, __) => const LegalScreen(type: 'privacy'),
      ),
      GoRoute(
        path: '/terms',
        builder: (_, __) => const LegalScreen(type: 'terms'),
      ),
    ],
    errorBuilder: (c, s) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => c.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
