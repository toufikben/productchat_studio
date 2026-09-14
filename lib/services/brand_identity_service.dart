import 'dart:convert';

import 'storage_service.dart';

class BrandIdentity {
  const BrandIdentity({this.name = '', this.primaryColor = '#6C5CE7', this.watermark = ''});

  final String name;
  final String primaryColor;
  final String watermark;

  Map<String, String> toJson() => {
        'name': name,
        'primaryColor': primaryColor,
        'watermark': watermark,
      };

  static BrandIdentity fromJson(Object? value) {
    if (value is! Map) return const BrandIdentity();
    return BrandIdentity(
      name: value['name'] as String? ?? '',
      primaryColor: value['primaryColor'] as String? ?? '#6C5CE7',
      watermark: value['watermark'] as String? ?? '',
    );
  }
}

class BrandIdentityService {
  BrandIdentityService({StorageService? storage}) : _storage = storage ?? storageService;

  static const key = 'brand.identity.v1';
  final StorageService _storage;

  BrandIdentity load() {
    final versioned = _storage.getVersionedJson(key);
    if (versioned != null) return BrandIdentity.fromJson(versioned);
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return const BrandIdentity();
    try { return BrandIdentity.fromJson(jsonDecode(raw)); } catch (_) { return const BrandIdentity(); }
  }

  Future<void> save(BrandIdentity identity) =>
      _storage.setVersionedJson(key, identity.toJson());
}

final brandIdentityService = BrandIdentityService();
