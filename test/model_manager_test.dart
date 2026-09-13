import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/model_manager.dart';

void main() {
  test('recognizes a model only when SHA-256 matches', () async {
    final root = await Directory.systemTemp.createTemp('productchat-model-test');
    addTearDown(() => root.delete(recursive: true));
    final manager = ModelManager(directoryProvider: () async => root);
    const model = ModelSpec(
      id: 'fixture',
      url: 'https://invalid.test/fixture',
      fileName: 'fixture.bin',
      sha256: '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
    );
    final file = await manager.modelFile(model);
    await file.writeAsString('hello');
    expect(await manager.isReady(model), isTrue);

    await file.writeAsString('corrupt');
    expect(await manager.isReady(model), isFalse);
  });

  test('delete removes the verified model and partial download', () async {
    final root = await Directory.systemTemp.createTemp('productchat-model-test');
    addTearDown(() => root.delete(recursive: true));
    final manager = ModelManager(directoryProvider: () async => root);
    const model = ModelSpec(
      id: 'fixture',
      url: 'https://invalid.test/fixture',
      fileName: 'fixture.bin',
      sha256: 'deadbeef',
    );
    final file = await manager.modelFile(model);
    await file.writeAsString('data');
    await File('${file.path}.part').writeAsString('partial');
    await manager.delete(model);
    expect(await file.exists(), isFalse);
    expect(await File('${file.path}.part').exists(), isFalse);
  });
}
