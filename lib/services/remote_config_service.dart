import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/feature_flags.dart';

/// RemoteConfigService — يجلب feature flags من GitHub.
///
/// الفكرة: ملف JSON بسيط على GitHub، بدون خادم.
/// يمكن تغيير حالة أي ميزة (stable ↔ beta ↔ comingSoon)
/// بدون تحديث التطبيق.
class RemoteConfigService {
  /// رابط الملف — استبدل `toufikben` بحسابك.
  static const _configUrl =
      'https://raw.githubusercontent.com/toufikben/productchat-config/main/features.json';

  static const _cacheKey = 'remote_config_data';
  static const _cacheTimeKey = 'remote_config_time';
  static const _cacheDuration = Duration(hours: 6);

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// يُستدعى عند بدء التطبيق.
  Future<void> initialize() async {
    await _applyCached();
    unawaited(_refreshInBackground());
  }

  /// جلب آخر نسخة من GitHub.
  Future<Map<String, String>?> fetch() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(_configUrl);
      if (response.statusCode != 200) return null;

      final dynamic raw = response.data;
      final dynamic decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! Map) return null;

      final dynamic features = decoded['features'];
      if (features is! Map) return null;

      final Map<String, String> result = {};
      features.forEach((dynamic key, dynamic value) {
        if (value is Map) {
          final dynamic tier = value['tier'];
          if (tier != null) {
            result[key.toString()] = tier.toString();
          }
        } else if (value != null) {
          result[key.toString()] = value.toString();
        }
      });

      return result;
    } catch (_) {
      return null;
    }
  }

  /// فحص يدوي (للمطور).
  Future<bool> forceRefresh() async {
    final overrides = await fetch();
    if (overrides == null) return false;

    final box = Hive.box('settings');
    await box.put(_cacheKey, jsonEncode(overrides));
    await box.put(_cacheTimeKey, DateTime.now().toIso8601String());

    FeatureFlags.applyRemoteOverrides(overrides);
    return true;
  }

  /// مسح النسخة المخزّنة.
  Future<void> clearCache() async {
    final box = Hive.box('settings');
    await box.delete(_cacheKey);
    await box.delete(_cacheTimeKey);
    FeatureFlags.clearRemoteOverrides();
  }

  // ────────────────────────────────────────────────────────────
  // Internal
  // ────────────────────────────────────────────────────────────

  Future<void> _applyCached() async {
    try {
      final box = Hive.box('settings');
      final dynamic cached = box.get(_cacheKey);
      if (cached is! String) return;

      final dynamic data = jsonDecode(cached);
      if (data is! Map) return;

      final Map<String, String> overrides = {};
      data.forEach((dynamic key, dynamic value) {
        overrides[key.toString()] = value.toString();
      });

      FeatureFlags.applyRemoteOverrides(overrides);
    } catch (_) {
      // ignore — استخدم defaults
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final box = Hive.box('settings');
      final dynamic lastUpdate = box.get(_cacheTimeKey);
      if (lastUpdate is String) {
        final DateTime? dt = DateTime.tryParse(lastUpdate);
        if (dt != null &&
            DateTime.now().difference(dt) < _cacheDuration) {
          return;
        }
      }

      final overrides = await fetch();
      if (overrides == null) return;

      await box.put(_cacheKey, jsonEncode(overrides));
      await box.put(_cacheTimeKey, DateTime.now().toIso8601String());

      FeatureFlags.applyRemoteOverrides(overrides);
    } catch (_) {
      // silent fail
    }
  }
}
