import 'dart:io';

import 'package:image/image.dart' as img;

/// Applies a visible, deterministic Free-tier watermark without network calls.
///
/// Fix (2026-09-15): The watermark text size is now proportional to the image
/// dimensions instead of always using [img.arial24] (24 px). On small images
/// (< 400 px tall) the fixed 24 px font could cover a significant portion of
/// the product. The new logic selects the largest bitmap font that keeps the
/// text height below 6 % of the image height, falling back to [img.arial14].
class FreeWatermarkService {
  const FreeWatermarkService();

  static const label = 'PRODUCTCHAT STUDIO  \u2022  FREE';

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

      // Choose font size proportional to the image height (≤ 6 %).
      // arial48 ≈ 48 px, arial24 ≈ 24 px, arial14 ≈ 14 px.
      final img.BitmapFont font;
      final int fontHeight;
      if (output.height >= 800) {
        font = img.arial48;
        fontHeight = 48;
      } else if (output.height >= 400) {
        font = img.arial24;
        fontHeight = 24;
      } else {
        font = img.arial14;
        fontHeight = 14;
      }

      final x = 18;
      final y = output.height - fontHeight - 10;
      img.drawString(output, label, font: font, x: x + 2, y: y + 2,
          color: shadow);
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
    return '\${path.substring(0, extensionStart)}_free_watermarked.png';
  }
}

const freeWatermarkService = FreeWatermarkService();
