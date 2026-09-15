import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/constants.dart';

import 'free_quota_service.dart';
import 'pro_service.dart';
import 'storage_service.dart';
import 'payment_history_service.dart';
import 'refund_service.dart';

/// Google Play product catalog. Prices are configured by Google Play and must
/// be read from ProductDetails.price; the roadmap values are reference prices.
class CreditProducts {
  static const starter = 'credits_100';
  static const standard = 'credits_500';
  static const largePack = 'credits_1200';
  static const monthly = 'pro_monthly';
  static const yearly = 'pro_yearly';
  static const lifetime = 'lifetime';

  static const amounts = <String, int>{
    starter: 100,
    standard: 500,
    largePack: 1200,
  };

  static const consumableIds = <String>{starter, standard, largePack};
  static const subscriptionIds = <String>{monthly, yearly};
  static const nonConsumableIds = <String>{lifetime};
  static const ids = <String>{
    ...consumableIds,
    ...subscriptionIds,
    ...nonConsumableIds,
  };

  static bool isSubscription(String productId) =>
      subscriptionIds.contains(productId);
  static bool isNonConsumable(String productId) =>
      nonConsumableIds.contains(productId);
  static bool isEntitlement(String productId) =>
      isSubscription(productId) || isNonConsumable(productId);
  static int? creditsFor(String productId) => amounts[productId];

  /// Only a newly purchased consumable with a stable purchase ID can grant
  /// credits locally. Production grant remains blocked until server receipt
  /// verification is connected.
  static bool shouldGrantCredits({
    required PurchaseStatus status,
    required String productId,
    required String? purchaseId,
  }) =>
      status == PurchaseStatus.purchased &&
      consumableIds.contains(productId) &&
      purchaseId != null &&
      purchaseId.trim().isNotEmpty &&
      creditsFor(productId) != null;
}

class CreditsLedger {
  CreditsLedger(this.storage);

  final StorageService storage;
  static const _balanceKey = 'credits.balance';
  static const _processedKey = 'credits.processedPurchases';

  int get balance => (storage.get(_balanceKey) as int?) ?? 0;

  Set<String> get processedPurchaseIds =>
      ((storage.get(_processedKey) as List?)?.whereType<String>().toSet()) ??
      <String>{};

  Future<void> addOnce(
      {required String purchaseId, required int amount}) async {
    if (amount <= 0 ||
        purchaseId.trim().isEmpty ||
        processedPurchaseIds.contains(purchaseId)) {
      return;
    }
    final processed = processedPurchaseIds..add(purchaseId);
    await storage.set(_balanceKey, balance + amount);
    await storage.set(_processedKey, processed.toList(growable: false));
  }

  Future<bool> spend(int amount) async {
    if (amount <= 0 || balance < amount) return false;
    await storage.set(_balanceKey, balance - amount);
    return true;
  }
}

class BillingService extends ChangeNotifier {
  BillingService({InAppPurchase? store, StorageService? storage})
      : _store = store,
        ledger = CreditsLedger(storage ?? storageService),
        freeQuota = FreeQuotaService(storage: storage ?? storageService),
        proService = ProService(storage: storage ?? storageService);

  final InAppPurchase? _store;
  InAppPurchase get _storeOrDefault => _store ?? InAppPurchase.instance;
  final CreditsLedger ledger;
  final FreeQuotaService freeQuota;
  final ProService proService;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = const [];
  bool available = false;
  bool loading = false;
  String? error;
  PurchaseStatus? lastPurchaseStatus;
  String? lastPurchaseProductId;
  String? lastEntitlementProductId;
  Future<void>? _initFuture;

  static const _billingTimeout = Duration(seconds: 15);

  int get credits => ledger.balance;
  bool canSpend(int amount) => amount <= 0 || credits >= amount;

  Future<bool> spend(int amount) async {
    final spent = await ledger.spend(amount);
    if (spent) notifyListeners();
    return spent;
  }

  Future<void> init() => _initFuture ??= _initialize();

  Future<void> retry() async {
    if (loading) return;
    _initFuture = null;
    await init();
  }

  Future<void> _initialize() async {
    try {
      // InAppPurchase.instance can throw on unsupported platforms; keep it
      // inside the non-fatal billing boundary.
      final store = _storeOrDefault;
      _subscription = store.purchaseStream.listen(
        _handlePurchasesSafely,
        onError: (Object value) {
          error = value.toString();
          loading = false;
          notifyListeners();
        },
      );
      available = await store.isAvailable().timeout(_billingTimeout);
      if (!available) {
        error = 'Google Play Billing is unavailable on this device.';
        return;
      }
      final response = await store
          .queryProductDetails(CreditProducts.ids)
          .timeout(_billingTimeout);
      products = response.productDetails;
      if (response.error != null) error = response.error!.message;
      if (response.notFoundIDs.isNotEmpty) {
        error = 'Products not configured: ${response.notFoundIDs.join(', ')}';
      }
      // Restored consumables are deliberately ignored by the purchase handler.
      await _restoreFromStore(store);
    } catch (value) {
      available = false;
      error = _friendlyBillingError(value);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _handlePurchasesSafely(
      List<PurchaseDetails> purchases) async {
    try {
      await _handlePurchases(purchases);
    } catch (value) {
      error = _friendlyBillingError(value);
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buy(ProductDetails product) async {
    await init();
    if (!available || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final sent = CreditProducts.isEntitlement(product.id)
          ? await _storeOrDefault.buyNonConsumable(purchaseParam: purchaseParam)
          : await _storeOrDefault.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: true,
            );
      if (!sent) error = 'Google Play did not start the purchase.';
    } catch (value) {
      error = _friendlyBillingError(value);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    await init();
    if (!available || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await _restoreFromStore(_storeOrDefault);
    } catch (value) {
      error = _friendlyBillingError(value);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreFromStore(InAppPurchase store) =>
      store.restorePurchases().timeout(_billingTimeout);

  String _friendlyBillingError(Object value) {
    if (value is TimeoutException) {
      return 'Google Play did not respond. Check your connection and try again.';
    }
    final text = value.toString();
    final normalized = text.toLowerCase();
    if (normalized.contains('item_not_found') ||
        normalized.contains('could not be found')) {
      return 'This product is not available in Google Play for this app version. Check the product ID, country, and internal-test installation.';
    }
    if (normalized.contains('item_unavailable')) {
      return 'This product is currently unavailable. Use the Google Play internal-test version and try again.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      lastPurchaseStatus = purchase.status;
      lastPurchaseProductId = purchase.productID;
      loading = purchase.status == PurchaseStatus.pending;

      if (purchase.status == PurchaseStatus.canceled) {
        await RefundService().logRefund(
          productId: purchase.productID,
          reason: 'cancelled',
          creditsRefunded: 0,
        );
      } else if (purchase.status == PurchaseStatus.error) {
        error = purchase.error?.message ?? 'Purchase failed.';
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (CreditProducts.isEntitlement(purchase.productID)) {
          lastEntitlementProductId = purchase.productID;
          final verificationData =
              purchase.verificationData.serverVerificationData.trim();
          if (purchase.productID == CreditProducts.lifetime &&
              verificationData.isNotEmpty) {
            await proService.activateLifetime(
              verificationData: verificationData,
            );
            error = proService.isLifetime
                ? null
                : 'Lifetime purchase could not be stored safely.';
          } else if (purchase.productID == CreditProducts.monthly &&
              verificationData.isNotEmpty) {
            await proService.activateMonthly(
                verificationData: verificationData);
            error = proService.isPro
                ? null
                : 'Monthly subscription could not be stored safely.';
          } else if (purchase.productID == CreditProducts.yearly &&
              verificationData.isNotEmpty) {
            await proService.activateYearly(verificationData: verificationData);
            error = proService.isPro
                ? null
                : 'Yearly subscription could not be stored safely.';
          } else {
            error = 'Purchase verification data was unavailable.';
          }
        } else if (!CreditProducts.shouldGrantCredits(
          status: purchase.status,
          productId: purchase.productID,
          purchaseId: purchase.purchaseID,
        )) {
          error = purchase.status == PurchaseStatus.restored
              ? 'Consumed credit purchases cannot be restored locally.'
              : 'Purchase could not be verified.';
        } else {
          final amount = CreditProducts.creditsFor(purchase.productID);
          final purchaseId = purchase.purchaseID;
          if (purchaseId == null || amount == null) {
            error = 'Purchase could not be verified.';
          } else {
            await ledger.addOnce(purchaseId: purchaseId, amount: amount);
            error = null;
          }
        }
      }
      if (purchase.status == PurchaseStatus.purchased && error == null) {
        await PaymentHistoryService().add(PaymentRecord(
          id: purchase.purchaseID ?? DateTime.now().millisecondsSinceEpoch.toString(),
          productId: purchase.productID,
          productName: _productName(purchase.productID),
          amount: _productAmount(purchase.productID),
          currency: 'USD',
          status: 'completed',
          date: DateTime.now(),
        ));
      }
      if (purchase.pendingCompletePurchase &&
          purchase.status != PurchaseStatus.pending) {
        try {
          await _storeOrDefault.completePurchase(purchase);
        } catch (value) {
          error = 'Google Play could not finalize this purchase: $value';
        }
      }
      notifyListeners();
    }
  }

  String _productName(String id) => AppConstants.displayNames[id] ?? id;

  double _productAmount(String id) {
    const known = <String, double>{
      AppConstants.iapProMonthly: 4.99,
      AppConstants.iapProYearly: 29.99,
      AppConstants.iapCredits100: 4.99,
      AppConstants.iapCredits500: 19.99,
      AppConstants.iapCredits1200: 39.99,
      AppConstants.iapLifetime: 79.99,
    };
    return known[id] ?? 0.0;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final billingService = BillingService();
