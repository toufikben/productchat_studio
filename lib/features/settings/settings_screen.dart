import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/billing_service.dart';

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
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!),
            ),
        ],
      ),
    );
  }
}
