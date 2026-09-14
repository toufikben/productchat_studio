import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:productchat_studio/services/billing_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
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
}
