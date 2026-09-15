import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../../models/edit_request.dart';

/// RelightService — Adjust image lighting with preset styles.
/// Pure Dart implementation — no model needed.
class RelightService {
  /// أنماط الإضاءة المتاحة.
  /// - studio: إضاءة استوديو محترفة (ساطعة، محايدة)
  /// - warm: إضاءة دافئة (نغمة صفراء)
  /// - cool: إضاءة باردة (نغمة زرقاء)
  /// - natural: إضاءة طبيعية (متوازنة)
  /// - dramatic: إضاءة درامية (تباين عالٍ)
  Future<EditResult> relight(
    String inputPath, {
    String style = 'studio',
    double intensity = 1.0,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null)
        return const EditResult(ok: false, error: 'Decode failed');

      final out =
          img.Image(width: src.width, height: src.height, numChannels: 3);

      final (rMul, gMul, bMul, contrast) = switch (style) {
        'warm' => (1.10, 1.02, 0.92, 1.05),
        'cool' => (0.92, 1.00, 1.12, 1.05),
        'natural' => (1.02, 1.02, 1.00, 1.00),
        'dramatic' => (1.00, 1.00, 1.00, 1.35),
        _ => (1.05, 1.05, 1.05, 1.10), // studio
      };

      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          final p = src.getPixel(x, y);
          double r = p.r.toDouble() * rMul;
          double g = p.g.toDouble() * gMul;
          double b = p.b.toDouble() * bMul;

          // Contrast adjustment
          r = (r - 128) * contrast + 128;
          g = (g - 128) * contrast + 128;
          b = (b - 128) * contrast + 128;

          // Brightness by intensity
          r *= intensity;
          g *= intensity;
          b *= intensity;

          out.setPixelRgb(
            x,
            y,
            r.round().clamp(0, 255),
            g.round().clamp(0, 255),
            b.round().clamp(0, 255),
          );
        }
      }

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_relight.png');
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
}
