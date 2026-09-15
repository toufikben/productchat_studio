import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:productchat_studio/services/billing_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BillingService can be constructed with injected storage without opening Play Billing', () {
    final billing = BillingService(storage: StorageService());

    expect(billing.available, isFalse);
    expect(billing.loading, isFalse);
    expect(billing.credits, 0);
    expect(billing.proService.isPro, isFalse);
    billing.dispose();
  });

  test('BillingService reports spendability without allowing invalid amounts', () async {
    final billing = BillingService(storage: StorageService());

    expect(billing.canSpend(0), isTrue);
    expect(billing.canSpend(-1), isTrue);
    expect(billing.canSpend(1), isFalse);
    expect(await billing.spend(1), isFalse);

    await billing.ledger.addOnce(purchaseId: 'txn-spend', amount: 100);
    expect(billing.canSpend(100), isTrue);
    expect(billing.canSpend(101), isFalse);
    expect(await billing.spend(40), isTrue);
    expect(billing.credits, 60);
    expect(await billing.spend(61), isFalse);
    expect(billing.credits, 60);
    billing.dispose();
  });

  test('credits are granted once per stable purchase id', () async {
    final ledger = CreditsLedger(StorageService());

    await ledger.addOnce(purchaseId: 'txn-1', amount: 100);
    await ledger.addOnce(purchaseId: 'txn-1', amount: 100);

    expect(ledger.balance, 100);
  });

  test('blank purchase ids and non-positive amounts never grant credits', () async {
    final ledger = CreditsLedger(StorageService());

    await ledger.addOnce(purchaseId: '', amount: 100);
    await ledger.addOnce(purchaseId: 'txn-invalid', amount: 0);

    expect(ledger.balance, 0);
  });

  test('spending never allows a negative balance', () async {
    final ledger = CreditsLedger(StorageService());
    await ledger.addOnce(purchaseId: 'txn-2', amount: 100);

    expect(await ledger.spend(101), isFalse);
    expect(ledger.balance, 100);
    expect(await ledger.spend(40), isTrue);
    expect(ledger.balance, 60);
  });

  test('credit packs stack by their catalog quantities without duplicate grant', () async {
    final ledger = CreditsLedger(StorageService());

    await ledger.addOnce(
      purchaseId: 'pack-100',
      amount: CreditProducts.creditsFor(CreditProducts.starter)!,
    );
    await ledger.addOnce(
      purchaseId: 'pack-500',
      amount: CreditProducts.creditsFor(CreditProducts.standard)!,
    );
    await ledger.addOnce(
      purchaseId: 'pack-1200',
      amount: CreditProducts.creditsFor(CreditProducts.largePack)!,
    );
    await ledger.addOnce(
      purchaseId: 'pack-500',
      amount: CreditProducts.creditsFor(CreditProducts.standard)!,
    );

    expect(ledger.balance, 1800);
  });

  test('Billing v2 catalog contains six products', () {
    expect(CreditProducts.ids, hasLength(6));
    expect(CreditProducts.ids, contains(CreditProducts.lifetime));
    expect(CreditProducts.isNonConsumable(CreditProducts.lifetime), isTrue);
    expect(CreditProducts.isEntitlement(CreditProducts.lifetime), isTrue);
  });

  test('credit packs map to the specified quantities', () {
    expect(CreditProducts.creditsFor(CreditProducts.starter), 100);
    expect(CreditProducts.creditsFor(CreditProducts.standard), 500);
    expect(CreditProducts.creditsFor(CreditProducts.largePack), 1200);
    expect(CreditProducts.creditsFor(CreditProducts.lifetime), isNull);
  });

  test('subscriptions and Lifetime never map to consumable credits', () {
    expect(CreditProducts.isSubscription(CreditProducts.monthly), isTrue);
    expect(CreditProducts.isSubscription(CreditProducts.yearly), isTrue);
    expect(CreditProducts.creditsFor(CreditProducts.monthly), isNull);
    expect(CreditProducts.creditsFor(CreditProducts.yearly), isNull);
    expect(CreditProducts.creditsFor(CreditProducts.lifetime), isNull);
  });

  test('only purchased consumable events can grant credits', () {
    expect(
      CreditProducts.shouldGrantCredits(
        status: PurchaseStatus.purchased,
        productId: CreditProducts.starter,
        purchaseId: 'txn-3',
      ),
      isTrue,
    );
    expect(
      CreditProducts.shouldGrantCredits(
        status: PurchaseStatus.restored,
        productId: CreditProducts.starter,
        purchaseId: 'txn-4',
      ),
      isFalse,
    );
    expect(
      CreditProducts.shouldGrantCredits(
        status: PurchaseStatus.purchased,
        productId: CreditProducts.lifetime,
        purchaseId: 'txn-5',
      ),
      isFalse,
    );
  });

  test('pending, error, restored, and entitlement events never grant consumable credits', () {
    for (final status in <PurchaseStatus>[
      PurchaseStatus.pending,
      PurchaseStatus.error,
      PurchaseStatus.restored,
    ]) {
      expect(
        CreditProducts.shouldGrantCredits(
          status: status,
          productId: CreditProducts.starter,
          purchaseId: 'txn-${status.name}',
        ),
        isFalse,
        reason: '${status.name} must not grant credits',
      );
    }

    expect(
      CreditProducts.shouldGrantCredits(
        status: PurchaseStatus.purchased,
        productId: CreditProducts.monthly,
        purchaseId: 'subscription-txn',
      ),
      isFalse,
    );
    expect(
      CreditProducts.shouldGrantCredits(
        status: PurchaseStatus.purchased,
        productId: CreditProducts.starter,
        purchaseId: '   ',
      ),
      isFalse,
    );
  });

  test('product catalog classifications are mutually exclusive', () {
    for (final id in CreditProducts.ids) {
      final isConsumable = CreditProducts.consumableIds.contains(id);
      final isEntitlement = CreditProducts.isEntitlement(id);
      expect(isConsumable && isEntitlement, isFalse, reason: id);
      expect(isConsumable || isEntitlement, isTrue, reason: id);
    }
  });

  test('BillingService completes purchases and grants a consumable once', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final fake = FakePurchasePlatform();
    InAppPurchasePlatform.instance = fake;
    final billing = BillingService(storage: StorageService());

    await billing.init();
    final purchase = PurchaseDetails(
      purchaseID: 'billing-test-1',
      productID: CreditProducts.starter,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: '1',
      status: PurchaseStatus.purchased,
    )..pendingCompletePurchase = true;

    fake.emit([purchase]);
    await Future<void>.delayed(Duration.zero);
    expect(billing.credits, 100);
    expect(fake.completed, 1);

    fake.emit([purchase]);
    await Future<void>.delayed(Duration.zero);
    expect(billing.credits, 100);
    expect(fake.completed, 2);

    billing.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test('BillingService ignores restored consumables and records purchase errors', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    final fake = FakePurchasePlatform();
    InAppPurchasePlatform.instance = fake;
    final billing = BillingService(storage: StorageService());

    await billing.init();
    fake.emit([
      PurchaseDetails(
        purchaseID: 'restored-credit',
        productID: CreditProducts.standard,
        verificationData: PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'server',
          source: 'test',
        ),
        transactionDate: '1',
        status: PurchaseStatus.restored,
      ),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(billing.credits, 0);
    expect(billing.error, contains('restored'));

    final failed = PurchaseDetails(
      productID: CreditProducts.starter,
      verificationData: PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'server',
        source: 'test',
      ),
      transactionDate: null,
      status: PurchaseStatus.error,
    );
    fake.emit([failed]);
    await Future<void>.delayed(Duration.zero);
    expect(billing.error, 'Purchase failed.');
    billing.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}

class FakePurchasePlatform extends InAppPurchasePlatform {
  final StreamController<List<PurchaseDetails>> _controller =
      StreamController<List<PurchaseDetails>>.broadcast();
  int completed = 0;

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
        productDetails: identifiers
            .map(
              (id) => ProductDetails(
                id: id,
                title: id,
                description: 'test product',
                price: '\$1.00',
                rawPrice: 1,
                currencyCode: 'USD',
              ),
            )
            .toList(),
        notFoundIDs: const [],
      );

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async => true;

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async => true;

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {}

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed++;

  @override
  Future<String> countryCode() async => 'US';
}
