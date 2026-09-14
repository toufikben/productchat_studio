import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Local representation of entitlement state. Production access must be
/// synchronized from the receipt-verification backend before activation.
class ProService extends ChangeNotifier {
  ProService({StorageService? storage}) : _storage = storage ?? storageService {
    _load();
  }

  static const isProKey = 'pro.isPro';
  static const lifetimeKey = 'pro.isLifetime';
  static const expiryKey = 'pro.expiry';

  final StorageService _storage;
  bool _isPro = false;
  bool _isLifetime = false;
  DateTime? _expiry;

  bool get isPro {
    if (_isLifetime) return true;
    if (!_isPro || _expiry == null) return false;
    return _expiry!.isAfter(DateTime.now());
  }

  bool get isLifetime => _isLifetime && _isPro;
  DateTime? get expiry => _expiry;

  int get daysRemaining {
    if (isLifetime) return -1;
    if (!isPro || _expiry == null) return 0;
    final days = _expiry!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  void _load() {
    _isPro = _storage.get(isProKey) as bool? ?? false;
    _isLifetime = _storage.get(lifetimeKey) as bool? ?? false;
    final value = _storage.getString(expiryKey);
    _expiry = value == null ? null : DateTime.tryParse(value);
    if (_isLifetime) {
      _isPro = true;
    } else if (_isPro && (_expiry == null || !_expiry!.isAfter(DateTime.now()))) {
      _isPro = false;
      _expiry = null;
      _persist();
    }
  }

  Future<void> activateSubscription(Duration duration) async {
    await _activateUntil(DateTime.now().add(duration));
  }

  Future<void> activateMonthly() => activateSubscription(const Duration(days: 30));

  Future<void> activateYearly() => activateSubscription(const Duration(days: 365));

  Future<void> activateLifetime() async {
    _isPro = true;
    _isLifetime = true;
    _expiry = null;
    await _persist();
    notifyListeners();
  }

  /// Applies a server-authoritative entitlement. A lifetime entitlement takes
  /// precedence over an expiry; an inactive/expired entitlement is cleared.
  Future<void> applyEntitlement({
    required bool active,
    required bool lifetime,
    DateTime? expiresAt,
  }) async {
    if (!active || (!lifetime && (expiresAt == null || !expiresAt.isAfter(DateTime.now())))) {
      await deactivate();
      return;
    }
    _isPro = true;
    _isLifetime = lifetime;
    _expiry = lifetime ? null : expiresAt;
    await _persist();
    notifyListeners();
  }

  Future<void> restoreFromPurchases({
    required bool hasLifetime,
    required DateTime? proExpiry,
  }) async {
    if (hasLifetime) {
      await activateLifetime();
    } else if (proExpiry != null && proExpiry.isAfter(DateTime.now())) {
      await _activateUntil(proExpiry);
    } else {
      await deactivate();
    }
  }

  Future<void> deactivate() async {
    _isPro = false;
    _isLifetime = false;
    _expiry = null;
    await _persist();
    notifyListeners();
  }

  Future<void> _activateUntil(DateTime expiry) async {
    _isPro = true;
    _isLifetime = false;
    _expiry = expiry;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.set(isProKey, _isPro);
    await _storage.set(lifetimeKey, _isLifetime);
    await _storage.set(expiryKey, _expiry?.toIso8601String());
  }
}
