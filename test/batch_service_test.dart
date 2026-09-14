import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/models/edit_request.dart';
import 'package:productchat_studio/models/edit_result.dart';
import 'package:productchat_studio/services/batch_service.dart';

void main() {
  test('Free users cannot start Batch processing', () async {
    final service = BatchService(isPro: false);

    await service.processAll(['/tmp/image.png']);

    expect(service.state.running, isFalse);
    expect(service.state.error, contains('requires Pro'));
  });

  test('Batch applies the injected processor and records successful outputs', () async {
    final directory = await Directory.systemTemp.createTemp('productchat_batch_test');
    final input = File('${directory.path}/input.png')..writeAsStringSync('input');
    final output = File('${directory.path}/output.png')..writeAsStringSync('output');
    final calls = <EditOp>[];

    final service = BatchService(
      isPro: true,
      processor: (path, operation) async {
        expect(path, input.path);
        calls.add(operation);
        return EditResult(ok: true, outputPath: output.path);
      },
    );

    await service.processAll([input.path]);

    expect(calls, [EditOp.removeBg]);
    expect(service.state.jobs.single.output, output.path);
    expect(service.state.jobs.single.error, isNull);
    expect(service.state.completed, 1);
    await directory.delete(recursive: true);
  });

  test('Batch surfaces processor failures per image and continues', () async {
    final directory = await Directory.systemTemp.createTemp('productchat_batch_failure_test');
    final first = File('${directory.path}/first.png')..writeAsStringSync('first');
    final second = File('${directory.path}/second.png')..writeAsStringSync('second');
    var calls = 0;

    final service = BatchService(
      isPro: true,
      processor: (path, operation) async {
        calls++;
        if (path == first.path) return const EditResult.failure('native failure');
        return EditResult(ok: true, outputPath: second.path);
      },
    );

    await service.processAll([first.path, second.path]);

    expect(calls, 2);
    expect(service.state.jobs[0].error, contains('native failure'));
    expect(service.state.jobs[1].output, second.path);
    expect(service.state.completed, 2);
    await directory.delete(recursive: true);
  });

  test('empty Batch input returns a clear error after Pro gate', () async {
    final service = BatchService(isPro: true);

    await service.processAll(const []);

    expect(service.state.error, contains('Select at least one image'));
  });
}
