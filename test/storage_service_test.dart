import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  test('versioned JSON round-trips through memory storage', () async {
    final storage = StorageService();
    await storage.setVersionedJson('test.key', {'value': 7});

    expect(storage.getVersionedJson('test.key'), {'value': 7});
  });

  test('unknown schema version is rejected', () async {
    final storage = StorageService();
    await storage.set('test.key', '{"version":99,"data":{"value":7}}');

    expect(storage.getVersionedJson('test.key'), isNull);
  });
}
