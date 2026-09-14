import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:productchat_studio/services/free_watermark_service.dart';

void main() {
  const fixtures = [
    'test/fixtures/patchmatch/flat_background_product.png',
    'test/fixtures/patchmatch/two_tone_background_product.png',
  ];

  for (final fixture in fixtures) {
    test('Free watermark preserves dimensions for $fixture', () async {
      final source = File(fixture);
      expect(await source.exists(), isTrue);
      final original = img.decodeImage(await source.readAsBytes());
      expect(original, isNotNull);

      final outputPath = await const FreeWatermarkService().apply(fixture);
      expect(outputPath, isNotNull);
      final output = File(outputPath!);
      expect(await output.exists(), isTrue);

      final encoded = img.decodeImage(await output.readAsBytes());
      expect(encoded, isNotNull);
      expect(encoded!.width, original!.width);
      expect(encoded.height, original.height);
      var changedPixels = 0;
      for (var y = encoded.height - 48; y < encoded.height - 8; y += 2) {
        for (var x = 12; x < encoded.width - 12; x += 2) {
          final before = original.getPixel(x, y);
          final after = encoded.getPixel(x, y);
          if (before.r != after.r ||
              before.g != after.g ||
              before.b != after.b ||
              before.a != after.a) {
            changedPixels++;
          }
        }
      }
      expect(changedPixels, greaterThan(0));
      expect(output.path.endsWith('_free_watermarked.png'), isTrue);
      await output.delete();
    });
  }
}
