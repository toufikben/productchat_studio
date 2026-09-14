import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/pro_service.dart';
import 'package:productchat_studio/services/purchase_security.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  test('purchase fingerprint is deterministic and non-empty', () {
    final first = PurchaseSecurity.fingerprint(
      productId: 'lifetime',
      verificationData: 'play-reference-1',
    );
    final second = PurchaseSecurity.fingerprint(
      productId: 'lifetime',
      verificationData: 'play-reference-1',
    );

    expect(first, isNotNull);
    expect(first, hasLength(64));
    expect(first, second);
    expect(first, isNot(contains('play-reference-1')));
  });

  test('empty purchase reference cannot produce a fingerprint', () {
    expect(
      PurchaseSecurity.fingerprint(
        productId: 'lifetime',
        verificationData: '',
      ),
      isNull,
    );
  });

  test('Lifetime requires a Play reference and stores only its fingerprint', () async {
    final storage = StorageService();
    final service = ProService(storage: storage);

    await service.activateLifetime(verificationData: 'play-reference-1');

    expect(service.isLifetime, isTrue);
    expect(service.productId, 'lifetime');
    expect(service.purchaseFingerprint, hasLength(64));
    expect(storage.getString('pro.purchaseFingerprint'), hasLength(64));
    expect(storage.getString('pro.purchaseFingerprint'),
        isNot(contains('play-reference-1')));
  });

  test('Lifetime cannot be activated without a Play reference', () async {
    final service = ProService(storage: StorageService());

    await service.activateLifetime(verificationData: '');

    expect(service.isPro, isFalse);
    expect(service.isLifetime, isFalse);
  });
}
