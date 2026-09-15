import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/feature_flags.dart';
import '../../services/billing_service.dart';
import '../../widgets/beta_badge.dart';
import '../../services/platform/locale_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.billing});

  final BillingService? billing;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BillingService get _billing => widget.billing ?? billingService;

  bool _restoring = false;
  String? _message;

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _message = null;
    });
    await _billing.restorePurchases();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _message = _billing.error ??
          (_billing.proService.isPro
              ? 'Entitlement restored from Google Play.'
              : 'No Pro or Lifetime purchase was restored.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = _billing.proService.isPro;
    final isLifetime = _billing.proService.isLifetime;
    final expiry = _billing.proService.expiry;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                    isPro ? Icons.verified : Icons.account_circle_outlined),
                title: Text(isLifetime
                    ? 'Lifetime active'
                    : isPro
                        ? 'Pro active'
                        : 'Free tier'),
                subtitle: Text(
                  isLifetime
                      ? 'Permanent local entitlement.'
                      : isPro
                          ? 'Expires: ${expiry?.toLocal() ?? 'managed by Google Play'}'
                          : 'PatchMatch only, with 3 monthly images.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _restoring ? null : _restore,
              icon: _restoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: const Text('Restore purchases'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/credits'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('View Pro and Lifetime plans'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Subscription Status'),
              subtitle: const Text('Manage your plan'),
              onTap: () => context.push('/subscription-status'),
            ),
            if (FeatureFlags.isEnabled('promoCode'))
              ListTile(
                leading: const Icon(Icons.card_giftcard),
              title: const Text('Promo Code'),
              subtitle: const Text('Redeem a code'),
              onTap: () => context.push('/promo-code'),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle:
                  Text(_languageName(localeController.locale.languageCode)),
              onTap: _chooseLanguage,
            ),
            const Divider(height: 28),
            if (FeatureFlags.isEnabled('brandIdentity'))
              ListTile(
                leading: const Icon(Icons.branding_watermark_outlined),
              title: const Text('Brand Identity'),
              subtitle: Text(
                  isPro ? 'Configure locally' : 'Pro or Lifetime required'),
                trailing: FeatureFlags.isBeta('brandIdentity')
                    ? BetaBadge(message: FeatureFlags.flag('brandIdentity').betaMessage)
                    : null,
                onTap: () => context.push('/brand'),
              ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Analytics'),
              subtitle: const Text('Local usage statistics'),
              onTap: () => context.push('/analytics'),
            ),
            if (FeatureFlags.isEnabled('referral'))
              ListTile(
                leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('Invite friends'),
              subtitle: const Text('Earn credits with referrals'),
              onTap: () => context.push('/referral'),
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Product roadmap'),
              subtitle: const Text('See upcoming features'),
              onTap: () => context.push('/roadmap'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              subtitle: Text(isPro
                  ? 'Full successful edit history'
                  : 'Latest 5 successful edits'),
              onTap: () => context.push('/history'),
            ),
            if (FeatureFlags.isEnabled('batchProcessing'))
              ListTile(
                leading: const Icon(Icons.collections_outlined),
              title: const Text('Batch processing'),
              subtitle:
                  Text(isPro ? 'Up to 100 images' : 'Pro or Lifetime required'),
                trailing: FeatureFlags.isBeta('batchProcessing')
                    ? BetaBadge(message: FeatureFlags.flag('batchProcessing').betaMessage)
                    : null,
                onTap: () => context.push('/batch'),
              ),
            if (FeatureFlags.isEnabled('modelCenter'))
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Models and capabilities'),
                trailing: FeatureFlags.isBeta('modelCenter')
                    ? BetaBadge(message: FeatureFlags.flag('modelCenter').betaMessage)
                    : null,
                onTap: () => context.push('/models'),
              ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQ'),
              onTap: () => context.push('/faq'),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Support'),
              onTap: () => context.push('/support'),
            ),
            ListTile(
              leading: const Icon(Icons.policy_outlined),
              title: const Text('Privacy and Terms'),
              onTap: () => context.push('/legal'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Recipes'),
              onTap: () => context.push('/recipes'),
            ),
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Review checklist'),
              onTap: () => context.push('/compliance'),
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Getting started'),
              onTap: () => context.push('/onboarding'),
            ),
            const Divider(height: 28),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('Version, links, credits'),
              onTap: () => context.push('/about'),
            ),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text('Check for Updates'),
              subtitle: const Text('Get the latest version'),
              onTap: () => context.push('/update'),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Favorites'),
              subtitle: const Text('Your saved images'),
              onTap: () => context.push('/favorites'),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve'),
              onTap: () => context.push('/feedback'),
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Editor Presets'),
              subtitle: const Text('Save operation combinations'),
              onTap: () => context.push('/presets'),
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Marketplace Integration'),
              subtitle: const Text('Shopify, WooCommerce'),
              onTap: () => context.push('/marketplace'),
            ),
            ListTile(
              leading: const Icon(Icons.developer_mode),
              title: const Text('Developer Options'),
              onTap: () => context.push('/developer'),
            ),
            const Divider(height: 28),
            const Text('Voice & Audio', style: TextStyle(fontWeight: FontWeight.w600)),
            ListTile(
              leading: const Icon(Icons.record_voice_over),
              title: const Text('Voice Settings'),
              subtitle: const Text('Language, speed, pitch'),
              onTap: () => context.push('/voice-settings'),
            ),
            ListTile(
              leading: const Icon(Icons.mic_none),
              title: const Text('Voice Presets'),
              subtitle: const Text('Saved voice commands'),
              onTap: () => context.push('/voice-presets'),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Voice Search'),
              subtitle: const Text('Search history by voice'),
              onTap: () => context.push('/voice-search'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_message!),
              ),
          ],
        ),
      ),
    );
  }

  String _languageName(String code) => switch (code) {
        'ar' => 'العربية',
        'de' => 'Deutsch',
        'es' => 'Español',
        'fr' => 'Français',
        'hi' => 'हिन्दी',
        'id' => 'Bahasa Indonesia',
        'it' => 'Italiano',
        'ja' => '日本語',
        'ko' => '한국어',
        'pt' => 'Português',
        'ru' => 'Русский',
        'tr' => 'Türkçe',
        'ur' => 'اردو',
        'fa' => 'فارسی',
        'zh' => '中文',
        _ => 'English',
      };

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Language'),
        children: [
          for (final code in const [
            'en',
            'ar',
            'fr',
            'es',
            'de',
            'it',
            'pt',
            'ru',
            'tr',
            'zh',
            'ja',
            'ko',
            'hi',
            'id',
            'fa',
            'ur',
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, code),
              child: Text(_languageName(code)),
            ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    await localeController.setLocale(Locale(selected));
    if (mounted) setState(() {});
  }
}
