import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// TestFixtureService — يحمّل صور اختبار من assets ويشغّلها.
///
/// الاستخدام: يظهر في Developer Options فقط.
class TestFixtureService {
  static const _assetPath = 'assets/test_fixtures/';

  /// قائمة صور الاختبار.
  static const fixtures = <TestFixture>[
    TestFixture(
      name: 'white_bg_simple',
      description: 'Product on pure white background',
      category: 'basic',
    ),
    TestFixture(
      name: 'complex_bg',
      description: 'Product with cluttered background',
      category: 'hard',
    ),
    TestFixture(
      name: 'hair_edges',
      description: 'Product with fine hair/fringe edges',
      category: 'hard',
    ),
    TestFixture(
      name: 'glass_transparent',
      description: 'Transparent glass object',
      category: 'hard',
    ),
    TestFixture(
      name: 'arabic_text',
      description: 'Product with Arabic text overlay',
      category: 'rtl',
    ),
    TestFixture(
      name: 'shadow_existing',
      description: 'Product with existing shadow',
      category: 'shadow',
    ),
  ];

  /// يحمّل صورة اختبار إلى ملف مؤقت.
  Future<File> loadFixture(String name) async {
    final data = await rootBundle.load('$_assetPath$name.png');
    final tmp = await Directory.systemTemp.createTemp('fixture_');
    final file = File('${tmp.path}/$name.png');
    await file.writeAsBytes(data.buffer.asUint8List());
    return file;
  }

  /// يحمّل كل الصور.
  Future<List<File>> loadAll() async {
    final files = <File>[];
    for (final fixture in fixtures) {
      try {
        files.add(await loadFixture(fixture.name));
      } catch (_) {}
    }
    return files;
  }

  /// يقارن صورتين (SSIM مبسط).
  double compareImages(String pathA, String pathB) {
    try {
      final a = img.decodeImage(File(pathA).readAsBytesSync());
      final b = img.decodeImage(File(pathB).readAsBytesSync());
      if (a == null || b == null) return 0.0;
      if (a.width != b.width || a.height != b.height) return 0.0;

      var diff = 0.0;
      var count = 0;
      final step = 8;

      for (var y = 0; y < a.height; y += step) {
        for (var x = 0; x < a.width; x += step) {
          final pa = a.getPixel(x, y);
          final pb = b.getPixel(x, y);
          diff += (pa.r - pb.r).abs() +
              (pa.g - pb.g).abs() +
              (pa.b - pb.b).abs();
          count++;
        }
      }

      final avgDiff = diff / (count * 3 * 255);
      return (1.0 - avgDiff).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }
}

class TestFixture {
  final String name;
  final String description;
  final String category;

  const TestFixture({
    required this.name,
    required this.description,
    required this.category,
  });
}
