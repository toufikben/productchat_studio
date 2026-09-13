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

  test('spending never allows a negative balance', () async {
    final ledger = CreditsLedger(StorageService());
    await ledger.addOnce(purchaseId: 'txn-2', amount: 100);

    expect(await ledger.spend(101), isFalse);
    expect(ledger.balance, 100);
    expect(await ledger.spend(40), isTrue);
    expect(ledger.balance, 60);
  });

  test('unknown product amounts are not part of the credit catalog', () {
    expect(CreditProducts.amounts['unknown_product'], isNull);
    expect(CreditProducts.amounts[CreditProducts.standard], 500);
  });
}
