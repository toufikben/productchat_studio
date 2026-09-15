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
    expect(service.productId, 'pro_monthly');
    expect(service.daysRemaining, inInclusiveRange(29, 30));
    expect(service.purchaseFingerprint, hasLength(64));
  });

  test('yearly entitlement expires after 365 days', () async {
    final service = ProService(storage: StorageService());

    await service.activateYearly(verificationData: 'play-yearly-1');

    expect(service.isPro, isTrue);
    expect(service.isLifetime, isFalse);
    expect(service.productId, 'pro_yearly');
    expect(service.daysRemaining, inInclusiveRange(364, 365));
    expect(service.expiry, isNotNull);
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

  test('restore accepts a valid monthly entitlement and persists it', () async {
    final storage = StorageService();
    final service = ProService(storage: storage);
    final expiry = DateTime.now().add(const Duration(days: 12));

    await service.restoreFromPurchase(
      productId: 'pro_monthly',
      verificationData: 'play-restore-monthly-1',
      expiry: expiry,
    );

    expect(service.isPro, isTrue);
    expect(service.productId, 'pro_monthly');
    expect(service.expiry, isNotNull);
    expect(
      service.verifyLocalPurchase(
        productId: 'pro_monthly',
        verificationData: 'play-restore-monthly-1',
      ),
      isTrue,
    );

    final reloaded = ProService(storage: storage);
    expect(reloaded.isPro, isTrue);
    expect(reloaded.productId, 'pro_monthly');
  });

  test('restore accepts Lifetime and persists permanent entitlement', () async {
    final storage = StorageService();
    final service = ProService(storage: storage);

    await service.restoreFromPurchase(
      productId: 'lifetime',
      verificationData: 'play-restore-lifetime-1',
    );

    expect(service.isPro, isTrue);
    expect(service.isLifetime, isTrue);
    expect(service.expiry, isNull);

    final reloaded = ProService(storage: storage);
    expect(reloaded.isLifetime, isTrue);
    expect(reloaded.daysRemaining, -1);
  });

  test('invalid product and empty verification data never activate Pro', () async {
    final service = ProService(storage: StorageService());

    await service.activateSubscription(
      const Duration(days: 30),
      productId: 'unknown_product',
      verificationData: 'play-invalid-product',
    );
    await service.activateMonthly(verificationData: '');
    await service.restoreFromPurchase(
      productId: 'unknown_product',
      verificationData: 'play-unknown-restore',
      expiry: DateTime.now().add(const Duration(days: 10)),
    );

    expect(service.isPro, isFalse);
    expect(service.productId, isNull);
    expect(service.purchaseFingerprint, isNull);
  });

  test('expired stored subscription is cleared on reload', () async {
    final storage = StorageService();
    await storage.set(ProService.isProKey, true);
    await storage.set(ProService.lifetimeKey, false);
    await storage.set(ProService.productKey, 'pro_yearly');
    await storage.set(ProService.expiryKey,
        DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String());

    final service = ProService(storage: storage);

    expect(service.isPro, isFalse);
    expect(service.productId, isNull);
    expect(storage.get(ProService.isProKey), isFalse);
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
