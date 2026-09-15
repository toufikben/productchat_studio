import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/billing_service.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(isPro ? Icons.verified : Icons.account_circle_outlined),
              title: Text(isLifetime ? 'Lifetime active' : isPro ? 'Pro active' : 'Free tier'),
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
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: Text(_languageName(localeController.locale.languageCode)),
            onTap: _chooseLanguage,
          ),
          const Divider(height: 28),
          ListTile(
            leading: const Icon(Icons.branding_watermark_outlined),
            title: const Text('Brand Identity'),
            subtitle: Text(isPro ? 'Configure locally' : 'Pro or Lifetime required'),
            onTap: () => context.push('/brand'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History'),
            subtitle: Text(isPro ? 'Full successful edit history' : 'Latest 5 successful edits'),
            onTap: () => context.push('/history'),
          ),
          ListTile(
            leading: const Icon(Icons.collections_outlined),
            title: const Text('Batch processing'),
            subtitle: Text(isPro ? 'Up to 100 images' : 'Pro or Lifetime required'),
            onTap: () => context.push('/batch'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Models and capabilities'),
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
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
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
