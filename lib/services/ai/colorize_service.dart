import 'dart:io';
import 'package:image/image.dart' as img;
import '../../models/edit_request.dart';

/// ColorizeService — Adds color to grayscale/B&W images.
/// Uses local luminance-to-color mapping (no model needed).
class ColorizeService {
  Future<EditResult> colorize(String inputPath) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null)
        return const EditResult(ok: false, error: 'Decode failed');

      final out =
          img.Image(width: src.width, height: src.height, numChannels: 3);

      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          final p = src.getPixel(x, y);
          final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();

          // Luminance-to-warm-color mapping
          final (r, g, b) = _luminanceToColor(lum);
          out.setPixelRgb(x, y, r, g, b);
        }
      }

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_colorized.png');
      await File(path).writeAsBytes(img.encodePng(out));
      return EditResult(
        ok: true,
        outputPath: path,
        creditsUsed: 2,
        duration: sw.elapsed,
      );
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }

  (int, int, int) _luminanceToColor(int lum) {
    if (lum < 40) return (30, 25, 20); // dark brown
    if (lum < 80) return (90, 70, 55); // brown
    if (lum < 130) return (160, 130, 100); // tan
    if (lum < 180) return (210, 180, 150); // beige
    if (lum < 220) return (240, 220, 200); // cream
    return (250, 245, 240); // warm white
  }
}
