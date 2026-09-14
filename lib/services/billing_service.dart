import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'pro_service.dart';
import 'storage_service.dart';

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

  static bool isSubscription(String productId) => subscriptionIds.contains(productId);
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

  Future<void> addOnce({required String purchaseId, required int amount}) async {
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
      : _store = store ?? InAppPurchase.instance,
        ledger = CreditsLedger(storage ?? storageService),
        proService = ProService(storage: storage ?? storageService);

  final InAppPurchase _store;
  final CreditsLedger ledger;
  final ProService proService;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = const [];
  bool available = false;
  bool loading = false;
  String? error;
  PurchaseStatus? lastPurchaseStatus;
  String? lastPurchaseProductId;
  String? lastEntitlementProductId;

  int get credits => ledger.balance;
  bool canSpend(int amount) => amount <= 0 || credits >= amount;

  Future<bool> spend(int amount) async {
    final spent = await ledger.spend(amount);
    if (spent) notifyListeners();
    return spent;
  }

  Future<void> init() async {
    if (_subscription != null) return;
    _subscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object value) {
        error = value.toString();
        loading = false;
        notifyListeners();
      },
    );
    available = await _store.isAvailable();
    if (!available) {
      error = 'Google Play Billing is unavailable on this device.';
      notifyListeners();
      return;
    }
    final response = await _store.queryProductDetails(CreditProducts.ids);
    products = response.productDetails;
    if (response.error != null) error = response.error!.message;
    if (response.notFoundIDs.isNotEmpty) {
      error = 'Products not configured: ${response.notFoundIDs.join(', ')}';
    }
    notifyListeners();
  }

  Future<void> buy(ProductDetails product) async {
    if (!available || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      final sent = CreditProducts.isEntitlement(product.id)
          ? await _store.buyNonConsumable(purchaseParam: purchaseParam)
          : await _store.buyConsumable(
              purchaseParam: purchaseParam,
              autoConsume: true,
            );
      if (!sent) error = 'Google Play did not start the purchase.';
    } catch (value) {
      error = value.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!available || loading) return;
    error = null;
    notifyListeners();
    try {
      await _store.restorePurchases();
    } catch (value) {
      error = value.toString();
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      lastPurchaseStatus = purchase.status;
      lastPurchaseProductId = purchase.productID;
      loading = purchase.status == PurchaseStatus.pending;

      if (purchase.status == PurchaseStatus.error) {
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
          } else {
            // Subscription expiry is not inferred locally from a purchase
            // event. Keep it pending until Google Play supplies a verified
            // entitlement source that includes expiry.
            error = 'Subscription entitlement requires a verified expiry.';
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
      if (purchase.pendingCompletePurchase &&
          purchase.status != PurchaseStatus.pending) {
        await _store.completePurchase(purchase);
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final billingService = BillingService();
