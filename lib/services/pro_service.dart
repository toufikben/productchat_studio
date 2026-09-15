import 'package:flutter/foundation.dart';

import 'purchase_security.dart';
import 'storage_service.dart';

/// Local representation of Google Play entitlement state.
///
/// Fix (2026-09-15): The previous [_load] logic cleared a Lifetime entitlement
/// when [_purchaseFingerprint] was null (e.g. data written by an older build
/// that did not store the fingerprint). The guard now only clears state whose
/// inconsistency cannot be explained by a missing fingerprint — specifically
/// subscriptions with a missing or expired expiry. Legacy Lifetime entries
/// without a fingerprint are left in place; they will be refreshed the next
/// time [activateLifetime] is called with a valid Play receipt.
///
/// This is not a replacement for Google Play's own billing service or
/// server-side purchase verification.
class ProService extends ChangeNotifier {
  ProService({StorageService? storage}) : _storage = storage ?? storageService {
    _load();
  }

  static const isProKey = 'pro.isPro';
  static const lifetimeKey = 'pro.isLifetime';
  static const expiryKey = 'pro.expiry';
  static const productKey = 'pro.productId';
  static const purchaseFingerprintKey = 'pro.purchaseFingerprint';

  final StorageService _storage;
  bool _isPro = false;
  bool _isLifetime = false;
  DateTime? _expiry;
  String? _productId;
  String? _purchaseFingerprint;

  bool get isPro {
    if (_isLifetime) return true;
    if (!_isPro || _expiry == null) return false;
    return _expiry!.isAfter(DateTime.now());
  }

  bool get isLifetime => _isLifetime && _isPro;
  DateTime? get expiry => _expiry;
  String? get productId => _productId;
  String? get purchaseFingerprint => _purchaseFingerprint;

  int get daysRemaining {
    if (isLifetime) return -1;
    if (!isPro || _expiry == null) return 0;
    final days = _expiry!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  void _load() {
    _isPro = _storage.get(isProKey) as bool? ?? false;
    _isLifetime = _storage.get(lifetimeKey) as bool? ?? false;
    _productId = _storage.getString(productKey);
    _purchaseFingerprint = _storage.getString(purchaseFingerprintKey);
    final value = _storage.getString(expiryKey);
    _expiry = value == null ? null : DateTime.tryParse(value);

    // A fully valid Lifetime record — keep as-is.
    final validLifetime =
        _isLifetime && _isPro && _productId == 'lifetime' && _purchaseFingerprint != null;
    if (validLifetime) return;

    // Legacy Lifetime record without a fingerprint: keep the entitlement but
    // do NOT clear it. The fingerprint will be added the next time the user
    // purchases or restores from Google Play.
    if (_isLifetime && _isPro && _productId == 'lifetime') return;

    // A subscription whose expiry is missing or already past is invalid and
    // must be cleared to avoid granting stale Pro access.
    if (_isPro && (_expiry == null || !_expiry!.isAfter(DateTime.now()))) {
      _clearInMemory();
      _persist();
    }
  }

  Future<void> activateSubscription(
    Duration duration, {
    required String productId,
    required String verificationData,
  }) async {
    if (productId != 'pro_monthly' && productId != 'pro_yearly') return;
    final fingerprint = PurchaseSecurity.fingerprint(
      productId: productId,
      verificationData: verificationData,
    );
    if (fingerprint == null) return;
    _isPro = true;
    _isLifetime = false;
    _expiry = DateTime.now().add(duration);
    _productId = productId;
    _purchaseFingerprint = fingerprint;
    await _persist();
    notifyListeners();
  }

  Future<void> activateMonthly({
    required String verificationData,
  }) =>
      activateSubscription(
        const Duration(days: 30),
        productId: 'pro_monthly',
        verificationData: verificationData,
      );

  Future<void> activateYearly({
    required String verificationData,
  }) =>
      activateSubscription(
        const Duration(days: 365),
        productId: 'pro_yearly',
        verificationData: verificationData,
      );

  Future<void> activateLifetime({required String verificationData}) async {
    final fingerprint = PurchaseSecurity.fingerprint(
      productId: 'lifetime',
      verificationData: verificationData,
    );
    if (fingerprint == null) return;
    _isPro = true;
    _isLifetime = true;
    _expiry = null;
    _productId = 'lifetime';
    _purchaseFingerprint = fingerprint;
    await _persist();
    notifyListeners();
  }

  /// Applies a locally observed Google Play entitlement. The caller must pass
  /// verificationData supplied by Google Play; callers cannot activate a
  /// state with only a product ID or a client-provided expiry.
  Future<void> restoreFromPurchase({
    required String productId,
    required String verificationData,
    DateTime? expiry,
  }) async {
    if (productId == 'lifetime') {
      await activateLifetime(verificationData: verificationData);
    } else if (productId == 'pro_monthly' && expiry != null) {
      await _activateUntil(
        productId: productId,
        expiry: expiry,
        verificationData: verificationData,
      );
    } else if (productId == 'pro_yearly' && expiry != null) {
      await _activateUntil(
        productId: productId,
        expiry: expiry,
        verificationData: verificationData,
      );
    }
  }

  /// Retained for migration callers; it now requires a Play reference and
  /// never activates an entitlement from a boolean alone.
  Future<void> restoreFromPurchases({
    required bool hasLifetime,
    required DateTime? proExpiry,
    required String verificationData,
  }) async {
    if (hasLifetime) {
      await activateLifetime(verificationData: verificationData);
    } else if (proExpiry != null) {
      await restoreFromPurchase(
        productId: 'pro_monthly',
        verificationData: verificationData,
        expiry: proExpiry,
      );
    } else {
      await deactivate();
    }
  }

  Future<void> deactivate() async {
    _clearInMemory();
    await _persist();
    notifyListeners();
  }

  Future<void> _activateUntil({
    required String productId,
    required DateTime expiry,
    required String verificationData,
  }) async {
    if (!expiry.isAfter(DateTime.now())) return;
    final fingerprint = PurchaseSecurity.fingerprint(
      productId: productId,
      verificationData: verificationData,
    );
    if (fingerprint == null) return;
    _isPro = true;
    _isLifetime = false;
    _expiry = expiry;
    _productId = productId;
    _purchaseFingerprint = fingerprint;
    await _persist();
    notifyListeners();
  }

  void _clearInMemory() {
    _isPro = false;
    _isLifetime = false;
    _expiry = null;
    _productId = null;
    _purchaseFingerprint = null;
  }

  bool verifyLocalPurchase({
    required String productId,
    required String verificationData,
  }) {
    final expectedFingerprint = PurchaseSecurity.fingerprint(
      productId: productId,
      verificationData: verificationData,
    );
    return expectedFingerprint != null &&
        expectedFingerprint == _purchaseFingerprint;
  }

  Future<void> applyLocalEntitlement({
    required String productId,
    required String verificationData,
    required bool isLifetime,
    Duration? duration,
  }) async {
    final fingerprint = PurchaseSecurity.fingerprint(
      productId: productId,
      verificationData: verificationData,
    );
    if (fingerprint == null) return;
    _isPro = true;
    _isLifetime = isLifetime;
    _expiry = isLifetime
        ? null
        : (duration != null ? DateTime.now().add(duration) : null);
    _productId = productId;
    _purchaseFingerprint = fingerprint;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storage.set(isProKey, _isPro);
    await _storage.set(lifetimeKey, _isLifetime);
    await _storage.set(expiryKey, _expiry?.toIso8601String());
    await _storage.set(productKey, _productId);
    await _storage.set(purchaseFingerprintKey, _purchaseFingerprint);
  }
}
