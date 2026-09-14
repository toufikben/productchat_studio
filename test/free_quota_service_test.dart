import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/core/constants.dart';
import 'package:productchat_studio/services/free_quota_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  test('starts with the configured monthly quota', () {
    final quota = FreeQuotaService(storage: StorageService());

    expect(quota.used, 0);
    expect(quota.remaining, AppConstants.freeMonthlyQuota);
    expect(quota.canUse(), isTrue);
  });

  test('consumes successful image slots and stops at the limit', () async {
    final quota = FreeQuotaService(storage: StorageService());

    expect(await quota.consume(), isTrue);
    expect(await quota.consume(images: 2), isTrue);
    expect(quota.used, 3);
    expect(quota.remaining, 0);
    expect(await quota.consume(), isFalse);
  });

  test('does not consume invalid or over-limit requests', () async {
    final quota = FreeQuotaService(storage: StorageService());

    expect(await quota.consume(images: 0), isFalse);
    expect(await quota.consume(images: 4), isFalse);
    expect(quota.used, 0);
  });

  test('a new month resets the quota during load', () async {
    final storage = StorageService();
    await storage.set(FreeQuotaService.monthKey, '2000-01');
    await storage.set(FreeQuotaService.usedKey, 3);

    final quota = FreeQuotaService(storage: storage);

    expect(quota.used, 0);
    expect(quota.remaining, AppConstants.freeMonthlyQuota);
  });

  test('stored usage is clamped to the product limit', () async {
    final storage = StorageService();
    final month = FreeQuotaService(storage: storage).month;
    await storage.set(FreeQuotaService.monthKey, month);
    await storage.set(FreeQuotaService.usedKey, 99);

    final quota = FreeQuotaService(storage: storage);

    expect(quota.used, AppConstants.freeMonthlyQuota);
    expect(quota.remaining, 0);
  });
}
