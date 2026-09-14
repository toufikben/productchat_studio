import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/brand_identity_service.dart';
import 'package:productchat_studio/services/history_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  test('Free history exposes only the latest five entries', () async {
    final service = HistoryService(storage: StorageService());
    for (var i = 0; i < 7; i++) {
      await service.record(path: '/tmp/image-$i.png', operation: 'removeBg');
    }

    expect(service.all(), hasLength(7));
    expect(service.visible(isPro: false), hasLength(5));
    expect(service.visible(isPro: true), hasLength(7));
  });

  test('history ignores invalid records', () async {
    final storage = StorageService();
    await storage.set(HistoryService.key, '[{"path":"","operation":"x"}]');

    expect(HistoryService(storage: storage).all(), isEmpty);
  });

  test('Brand Identity persists locally', () async {
    final storage = StorageService();
    final service = BrandIdentityService(storage: storage);
    const identity = BrandIdentity(
      name: 'Demo Brand',
      primaryColor: '#112233',
      watermark: 'Demo',
    );

    await service.save(identity);
    final loaded = service.load();

    expect(loaded.name, identity.name);
    expect(loaded.primaryColor, identity.primaryColor);
    expect(loaded.watermark, identity.watermark);
  });
}
