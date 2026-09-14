import 'package:flutter_test/flutter_test.dart';
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

  test('unknown product amounts are not part of the credit catalog', () {
    expect(CreditProducts.creditsFor('unknown_product'), isNull);
    expect(CreditProducts.creditsFor(CreditProducts.standard), 500);
  });

  test('subscription products are separated from consumable products', () {
    expect(CreditProducts.isSubscription(CreditProducts.monthly), isTrue);
    expect(CreditProducts.isSubscription(CreditProducts.yearly), isTrue);
    expect(CreditProducts.isSubscription(CreditProducts.standard), isFalse);
    expect(CreditProducts.creditsFor(CreditProducts.monthly), isNull);
    expect(CreditProducts.creditsFor(CreditProducts.yearly), isNull);
  });

  test('subscription products never map to consumable credits', () {
    expect(CreditProducts.amounts.keys, containsAll(CreditProducts.consumableIds));
    expect(CreditProducts.amounts.keys, isNot(contains(CreditProducts.monthly)));
    expect(CreditProducts.amounts.keys, isNot(contains(CreditProducts.yearly)));
  });
}
