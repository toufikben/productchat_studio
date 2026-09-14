import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/billing_service.dart';
import '../../services/platform/locale_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _restoring = false;
  String? _message;

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _message = null;
    });
    await billingService.restorePurchases();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _message = billingService.error ??
          (billingService.proService.isPro
              ? 'Entitlement restored from Google Play.'
              : 'No Pro or Lifetime purchase was restored.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = billingService.proService.isPro;
    final isLifetime = billingService.proService.isLifetime;
    final expiry = billingService.proService.expiry;
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
            subtitle: Text(_languageName(localeProvider.locale.languageCode)),
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
        'fr' => 'Français',
        _ => 'English',
      };

  Future<void> _chooseLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Language'),
        children: [
          for (final option in const [
            ('en', 'English'),
            ('ar', 'العربية'),
            ('fr', 'Français'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.$1),
              child: Text(option.$2),
            ),
        ],
      ),
    );
    if (!mounted || selected == null) return;
    await localeProvider.setLocale(Locale(selected));
    if (mounted) setState(() {});
  }
}
