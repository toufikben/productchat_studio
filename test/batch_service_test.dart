import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/batch_service.dart';

void main() {
  test('Free users cannot start Batch processing', () async {
    final service = BatchService();

    await service.processAll(['/tmp/image.png']);

    expect(service.state.running, isFalse);
    expect(service.state.error, contains('requires Pro'));
  });

  test('empty Batch input returns a clear error', () async {
    final service = BatchService();

    await service.processAll(const []);

    expect(service.state.error, contains('requires Pro'));
  });
}
