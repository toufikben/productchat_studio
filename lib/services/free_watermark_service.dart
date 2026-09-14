import 'dart:io';

import 'package:image/image.dart' as img;

/// Applies a visible, deterministic Free-tier watermark without network calls.
class FreeWatermarkService {
  const FreeWatermarkService();

  static const label = 'PRODUCTCHAT STUDIO  •  FREE';

  Future<String?> apply(String inputPath) async {
    if (inputPath.trim().isEmpty) return null;
    try {
      final input = File(inputPath);
      if (!await input.exists()) return null;
      final decoded = img.decodeImage(await input.readAsBytes());
      if (decoded == null) return null;

      final output = decoded;
      final color = img.ColorRgba8(255, 255, 255, 190);
      final shadow = img.ColorRgba8(0, 0, 0, 180);
      final font = img.arial24;
      final x = 18;
      final y = output.height - 42;
      img.drawString(output, label, font: font, x: x + 2, y: y + 2, color: shadow);
      img.drawString(output, label, font: font, x: x, y: y, color: color);

      final outputPath = _watermarkedPath(inputPath);
      await File(outputPath).writeAsBytes(img.encodePng(output), flush: true);
      return outputPath;
    } catch (_) {
      return null;
    }
  }

  String _watermarkedPath(String path) {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    final dot = path.lastIndexOf('.');
    final baseStart = slash < 0 ? 0 : slash + 1;
    final extensionStart = dot > baseStart ? dot : path.length;
    return '${path.substring(0, extensionStart)}_free_watermarked.png';
  }
}

const freeWatermarkService = FreeWatermarkService();
