import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/brand_identity_service.dart';
import '../../services/billing_service.dart';

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key});

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final _name = TextEditingController();
  final _color = TextEditingController();
  final _watermark = TextEditingController();
  String? _message;

  @override
  void initState() {
    super.initState();
    final identity = brandIdentityService.load();
    _name.text = identity.name;
    _color.text = identity.primaryColor;
    _watermark.text = identity.watermark;
  }

  @override
  void dispose() {
    _name.dispose();
    _color.dispose();
    _watermark.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!billingService.proService.isPro) {
      setState(() => _message = 'Brand Identity requires Pro or Lifetime.');
      return;
    }
    await brandIdentityService.save(
      BrandIdentity(
        name: _name.text.trim(),
        primaryColor: _color.text.trim(),
        watermark: _watermark.text.trim(),
      ),
    );
    if (mounted) setState(() => _message = 'Brand Identity saved locally.');
  }

  @override
  Widget build(BuildContext context) {
    final isPro = billingService.proService.isPro;
    return Scaffold(
      appBar: AppBar(title: const Text('Brand Identity')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: Icon(isPro ? Icons.verified_outlined : Icons.lock_outline),
              title: Text(isPro ? 'Pro feature enabled' : 'Pro feature'),
              subtitle: Text(
                isPro
                    ? 'Stored locally and available offline.'
                    : 'Upgrade to Pro or Lifetime to configure brand identity.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            enabled: isPro,
            decoration: const InputDecoration(labelText: 'Brand name'),
          ),
          TextField(
            controller: _color,
            enabled: isPro,
            decoration: const InputDecoration(labelText: 'Primary color (hex)'),
          ),
          TextField(
            controller: _watermark,
            enabled: isPro,
            decoration: const InputDecoration(labelText: 'Brand watermark text'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isPro ? _save : () => context.push('/credits'),
            icon: Icon(isPro ? Icons.save : Icons.workspace_premium),
            label: Text(isPro ? 'Save locally' : 'Open Pro plans'),
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
