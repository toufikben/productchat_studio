import 'dart:io';
import 'package:image/image.dart' as img;
import '../models/edit_request.dart';

/// BackgroundBlurService — Blurs background while keeping subject sharp.
class BackgroundBlurService {
  Future<EditResult> blurBackground(
    String inputPath, {
    double blurRadius = 15.0,
    double subjectScale = 0.6,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      // Blur entire image
      final blurred = img.gaussianBlur(src, radius: blurRadius.toInt());

      // Create output
      final out = img.Image(width: src.width, height: src.height, numChannels: 4);

      // Elliptical subject mask
      final cx = src.width / 2;
      final cy = src.height / 2;
      final rx = src.width * subjectScale / 2;
      final ry = src.height * subjectScale / 2;

      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          // Distance from center (normalized)
          final dx = (x - cx) / rx;
          final dy = (y - cy) / ry;
          final dist = (dx * dx + dy * dy);

          // Feathering (1 = subject, 0 = background)
          double alpha;
          if (dist < 0.7) {
            alpha = 1.0;
          } else if (dist < 1.0) {
            alpha = 1.0 - (dist - 0.7) / 0.3;
          } else {
            alpha = 0.0;
          }
          alpha = alpha.clamp(0.0, 1.0);

          final orig = src.getPixel(x, y);
          final blur = blurred.getPixel(x, y);

          final r = (orig.r * alpha + blur.r * (1 - alpha)).round().clamp(0, 255);
          final g = (orig.g * alpha + blur.g * (1 - alpha)).round().clamp(0, 255);
          final b = (orig.b * alpha + blur.b * (1 - alpha)).round().clamp(0, 255);

          out.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_blur.png');
      await File(path).writeAsBytes(img.encodePng(out));
      return EditResult(
        ok: true,
        outputPath: path,
        creditsUsed: 1,
        duration: sw.elapsed,
      );
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }
}
