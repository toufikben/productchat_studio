import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/pro_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  test('starts inactive without entitlement', () {
    final service = ProService(storage: StorageService());

    expect(service.isPro, isFalse);
    expect(service.isLifetime, isFalse);
    expect(service.daysRemaining, 0);
  });

  test('monthly entitlement expires after thirty days', () async {
    final service = ProService(storage: StorageService());

    await service.activateMonthly(verificationData: 'play-monthly-1');

    expect(service.isPro, isTrue);
    expect(service.isLifetime, isFalse);
    expect(service.daysRemaining, inInclusiveRange(29, 30));
    expect(service.purchaseFingerprint, hasLength(64));
  });

  test('lifetime entitlement never has an expiry', () async {
    final service = ProService(storage: StorageService());

    await service.activateLifetime(verificationData: 'play-lifetime-1');

    expect(service.isPro, isTrue);
    expect(service.isLifetime, isTrue);
    expect(service.expiry, isNull);
    expect(service.daysRemaining, -1);
    expect(service.purchaseFingerprint, hasLength(64));
  });

  test('expired restored entitlement is rejected', () async {
    final service = ProService(storage: StorageService());

    await service.restoreFromPurchase(
      productId: 'pro_monthly',
      verificationData: 'play-expired-1',
      expiry: DateTime.now().subtract(const Duration(minutes: 1)),
    );

    expect(service.isPro, isFalse);
    expect(service.isLifetime, isFalse);
  });

  test('deactivate clears subscription and lifetime state', () async {
    final service = ProService(storage: StorageService());

    await service.activateLifetime(verificationData: 'play-lifetime-2');
    await service.deactivate();

    expect(service.isPro, isFalse);
    expect(service.isLifetime, isFalse);
    expect(service.expiry, isNull);
    expect(service.productId, isNull);
    expect(service.purchaseFingerprint, isNull);
  });
}
