import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'storage_service.dart';

class CreditProducts {
  static const starter = 'credits_100';
  static const standard = 'credits_500';
  static const pro = 'credits_1200';
  static const monthly = 'pro_monthly';
  static const yearly = 'pro_yearly';

  static const amounts = <String, int>{
    starter: 100,
    standard: 500,
    pro: 1200,
    monthly: 600,
    yearly: 9000,
  };

  static const consumableIds = <String>{starter, standard, pro};
  static const subscriptionIds = <String>{monthly, yearly};
  static const ids = <String>{...consumableIds, ...subscriptionIds};

  static bool isSubscription(String productId) => subscriptionIds.contains(productId);
}

class CreditsLedger {
  CreditsLedger(this.storage);

  final StorageService storage;
  static const _balanceKey = 'credits.balance';
  static const _processedKey = 'credits.processedPurchases';

  int get balance => (storage.get(_balanceKey) as int?) ?? 0;

  Set<String> get processedPurchaseIds =>
      ((storage.get(_processedKey) as List?)?.whereType<String>().toSet()) ?? <String>{};

  Future<void> addOnce({required String purchaseId, required int amount}) async {
    if (amount <= 0 || processedPurchaseIds.contains(purchaseId)) return;
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
        ledger = CreditsLedger(storage ?? storageService);

  final InAppPurchase _store;
  final CreditsLedger ledger;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = const [];
  bool available = false;
  bool loading = false;
  String? error;
  PurchaseStatus? lastPurchaseStatus;

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
      final sent = CreditProducts.isSubscription(product.id)
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
    if (!available) return;
    error = null;
    notifyListeners();
    try {
      // Consumable credits cannot be restored by Google Play. Restore is kept
      // for platform consistency and future non-consumable products.
      await _store.restorePurchases();
    } catch (value) {
      error = value.toString();
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      lastPurchaseStatus = purchase.status;
      notifyListeners();
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error) {
        error = purchase.error?.message ?? 'Purchase failed.';
      } else if (purchase.status == PurchaseStatus.purchased) {
        final purchaseId = purchase.purchaseID;
        final amount = CreditProducts.amounts[purchase.productID];
        // Never grant credits without a stable store transaction identifier.
        if (purchaseId == null || amount == null) {
          error = 'Purchase could not be verified.';
        } else {
          await ledger.addOnce(purchaseId: purchaseId, amount: amount);
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
