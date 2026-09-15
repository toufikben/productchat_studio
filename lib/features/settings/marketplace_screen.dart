import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _shopifyShop = TextEditingController();
  final _shopifyToken = TextEditingController();
  final _wooUrl = TextEditingController();
  final _wooKey = TextEditingController();
  final _wooSecret = TextEditingController();

  bool get _shopifyConnected =>
      Hive.box('settings').get('shopify_creds') != null;

  bool get _wooConnected =>
      Hive.box('settings').get('woo_creds') != null;

  Future<void> _saveShopify() async {
    if (_shopifyShop.text.isEmpty || _shopifyToken.text.isEmpty) return;
    await Hive.box('settings').put('shopify_creds', {
      'shop': _shopifyShop.text,
      'token': _shopifyToken.text,
    });
    if (mounted) {
      showSuccessSnack(context, 'Shopify connected');
      setState(() {});
    }
  }

  Future<void> _saveWoo() async {
    if (_wooUrl.text.isEmpty || _wooKey.text.isEmpty || _wooSecret.text.isEmpty) return;
    await Hive.box('settings').put('woo_creds', {
      'url': _wooUrl.text,
      'key': _wooKey.text,
      'secret': _wooSecret.text,
    });
    if (mounted) {
      showSuccessSnack(context, 'WooCommerce connected');
      setState(() {});
    }
  }

  Future<void> _disconnect(String which) async {
    await Hive.box('settings').delete(which == 'shopify' ? 'shopify_creds' : 'woo_creds');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace Integration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _platformCard(
            name: 'Shopify',
            icon: Icons.shopping_bag,
            brandColor: const Color(0xFF96BF48),
            connected: _shopifyConnected,
            fields: [
              _Field(controller: _shopifyShop, label: 'Store URL', hint: 'mystore.myshopify.com'),
              _Field(controller: _shopifyToken, label: 'Access Token', hint: 'shpat_...', obscure: true),
            ],
            onSave: _saveShopify,
            onDisconnect: () => _disconnect('shopify'),
          ),
          const SizedBox(height: 16),
          _platformCard(
            name: 'WooCommerce',
            icon: Icons.storefront,
            brandColor: const Color(0xFF7F54B3),
            connected: _wooConnected,
            fields: [
              _Field(controller: _wooUrl, label: 'Store URL', hint: 'https://mystore.com'),
              _Field(controller: _wooKey, label: 'Consumer Key', hint: 'ck_...', obscure: true),
              _Field(controller: _wooSecret, label: 'Consumer Secret', hint: 'cs_...', obscure: true),
            ],
            onSave: _saveWoo,
            onDisconnect: () => _disconnect('woo'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Note', style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(height: 8),
                Text('After connecting, you can upload images directly from the editor. '
                    'All credentials are stored locally on your device only.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformCard({
    required String name,
    required IconData icon,
    required Color brandColor,
    required bool connected,
    required List<_Field> fields,
    required VoidCallback onSave,
    required VoidCallback onDisconnect,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: connected ? brandColor.withValues(alpha: 0.5) : AppColors.border,
        width: connected ? 1.5 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          AppIcons.outline(icon, size: 48, color: brandColor),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(connected ? '✓ Connected' : 'Not connected',
                style: TextStyle(
                  color: connected ? AppColors.success : AppColors.textTertiary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          )),
          if (connected)
            TextButton(
              onPressed: onDisconnect,
              child: const Text('Disconnect',
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
            ),
        ]),
        if (!connected) ...[
          const Divider(height: 24),
          ...fields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: f.controller,
              obscureText: f.obscure,
              decoration: InputDecoration(
                labelText: f.label,
                hintText: f.hint,
              ),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSave,
              child: const Text('Save'),
            ),
          ),
        ],
      ],
    ),
  );
}

class _Field {
  final TextEditingController controller;
  final String label, hint;
  final bool obscure;
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
  });
}

// ═══════════════════════════════════════════════════════════════
// Marketplace Service (Upload helper)
// ═══════════════════════════════════════════════════════════════
class MarketplaceService {
  static Future<UploadResult> uploadToShopify(String imagePath) async {
    final creds = Hive.box('settings').get('shopify_creds') as Map?;
    if (creds == null) return UploadResult.error('Not connected');
    try {
      final bytes = await File(imagePath).readAsBytes();
      final b64 = base64Encode(bytes);
      final dio = Dio(BaseOptions(
        baseUrl: 'https://${creds['shop']}/admin/api/2025-01',
        headers: {
          'X-Shopify-Access-Token': creds['token'],
          'Content-Type': 'application/json',
        },
      ));
      final res = await dio.post('/images.json', data: {
        'image': {'attachment': b64, 'filename': imagePath.split('/').last},
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        return UploadResult.success('${res.data['image']?['id']}');
      }
      return UploadResult.error('Status: ${res.statusCode}');
    } catch (e) {
      return UploadResult.error('$e');
    }
  }

  static Future<UploadResult> uploadToWoo(String imagePath) async {
    final creds = Hive.box('settings').get('woo_creds') as Map?;
    if (creds == null) return UploadResult.error('Not connected');
    try {
      final dio = Dio(BaseOptions(
        baseUrl: '${creds['url']}/wp-json/wp/v2',
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${creds['key']}:${creds['secret']}'))}',
        },
      ));
      final bytes = await File(imagePath).readAsBytes();
      final res = await dio.post('/media',
        data: bytes,
        options: Options(headers: {
          'Content-Disposition': 'attachment; filename="${imagePath.split('/').last}"',
          'Content-Type': 'image/png',
        }));
      if (res.statusCode == 201) return UploadResult.success('${res.data['id']}');
      return UploadResult.error('Status: ${res.statusCode}');
    } catch (e) {
      return UploadResult.error('$e');
    }
  }
}

class UploadResult {
  final bool ok;
  final String? id;
  final String? error;
  const UploadResult({required this.ok, this.id, this.error});
  factory UploadResult.success(String id) => UploadResult(ok: true, id: id);
  factory UploadResult.error(String e) => UploadResult(ok: false, error: e);
}
