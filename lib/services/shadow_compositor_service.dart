import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/edit_request.dart';

/// ShadowCompositorService — ظل حتمي (deterministic).
///
/// القرار من 2026-09-15: استخدم compositor حتمي، لا AI.
///
/// الميزات:
///   • Gaussian blur حقيقي (kernel 2D)
///   • Offset قابل للتحكم
///   • Opacity قابلة للتحكم
///   • 4 اتجاهات (bottom, top, left, right)
class ShadowCompositorService {
  /// يضيف ظلاً حتمياً على الصورة.
  Future<EditResult> apply(
    String inputPath, {
    ShadowConfig config = const ShadowConfig(),
  }) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) {
        return const EditResult(ok: false, error: 'Decode failed');
      }

      // 1. Extract alpha channel
      final alpha = _extractAlpha(src);

      // 2. Shift alpha by offset
      final shifted = _shiftAlpha(
        alpha,
        src.width,
        src.height,
        config.offsetX,
        config.offsetY,
      );

      // 3. Apply Gaussian blur (real 2D, not box)
      final blurred = _gaussianBlur2D(
        shifted,
        src.width,
        src.height,
        config.blurRadius,
      );

      // 4. Build output
      final out = img.Image(
        width: src.width,
        height: src.height,
        numChannels: 4,
      );

      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          final sp = src.getPixel(x, y);
          final sA = blurred[y * src.width + x];

          // Shadow intensity based on config
          final shadowAlpha =
              (sA * config.opacity).round().clamp(0, 255);

          // Darken product where shadow overlaps
          final factor =
              1.0 - (shadowAlpha / 255.0) * config.darkness;

          final r = (sp.r * factor).round().clamp(0, 255);
          final g = (sp.g * factor).round().clamp(0, 255);
          final b = (sp.b * factor).round().clamp(0, 255);

          // Final alpha = max(product alpha, shadow alpha)
          final finalAlpha = math.max(
            sp.a.toInt(),
            shadowAlpha,
          );

          out.setPixelRgba(x, y, r, g, b, finalAlpha);
        }
      }

      final outPath = inputPath.replaceAll(
        RegExp(r'\.[^.]+$'),
        '_shadow.png',
      );
      await File(outPath).writeAsBytes(img.encodePng(out));

      return EditResult(
        ok: true,
        outputPath: outPath,
        creditsUsed: 1,
        duration: sw.elapsed,
      );
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════

  Uint8List _extractAlpha(img.Image im) {
    final a = Uint8List(im.width * im.height);
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        a[y * im.width + x] = im.getPixel(x, y).a.toInt();
      }
    }
    return a;
  }

  Uint8List _shiftAlpha(
    Uint8List src,
    int w,
    int h,
    int dx,
    int dy,
  ) {
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final sx = x - dx;
        final sy = y - dy;
        if (sx >= 0 && sx < w && sy >= 0 && sy < h) {
          out[y * w + x] = src[sy * w + sx];
        }
      }
    }
    return out;
  }

  /// True 2D Gaussian blur (separable kernel).
  /// Much better quality than box blur.
  Uint8List _gaussianBlur2D(
    Uint8List src,
    int w,
    int h,
    int radius,
  ) {
    if (radius <= 0) return src;

    // Generate 1D Gaussian kernel
    final sigma = radius / 3.0;
    final kernelSize = radius * 2 + 1;
    final kernel = List<double>.filled(kernelSize, 0.0);
    var sum = 0.0;

    for (var i = 0; i < kernelSize; i++) {
      final x = i - radius;
      kernel[i] = math.exp(-(x * x) / (2 * sigma * sigma));
      sum += kernel[i];
    }
    for (var i = 0; i < kernelSize; i++) {
      kernel[i] /= sum;
    }

    // Horizontal pass
    final temp = Float32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var v = 0.0;
        for (var k = 0; k < kernelSize; k++) {
          final nx = x - radius + k;
          if (nx >= 0 && nx < w) {
            v += src[y * w + nx] * kernel[k];
          }
        }
        temp[y * w + x] = v;
      }
    }

    // Vertical pass
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var v = 0.0;
        for (var k = 0; k < kernelSize; k++) {
          final ny = y - radius + k;
          if (ny >= 0 && ny < h) {
            v += temp[ny * w + x] * kernel[k];
          }
        }
        out[y * w + x] = v.round().clamp(0, 255);
      }
    }

    return out;
  }
}

/// ShadowConfig — كل الإعدادات قابلة للتخصيص.
class ShadowConfig {
  final int offsetX;
  final int offsetY;
  final int blurRadius;
  final double opacity;
  final double darkness;

  const ShadowConfig({
    this.offsetX = 0,
    this.offsetY = 12,
    this.blurRadius = 15,
    this.opacity = 0.5,
    this.darkness = 0.4,
  });

  // ─── Presets ───
  static const soft = ShadowConfig(
    offsetX: 0,
    offsetY: 8,
    blurRadius: 12,
    opacity: 0.4,
    darkness: 0.3,
  );

  static const hard = ShadowConfig(
    offsetX: 4,
    offsetY: 6,
    blurRadius: 4,
    opacity: 0.6,
    darkness: 0.5,
  );

  static const natural = ShadowConfig(
    offsetX: 2,
    offsetY: 14,
    blurRadius: 18,
    opacity: 0.55,
    darkness: 0.45,
  );

  static const dramatic = ShadowConfig(
    offsetX: 8,
    offsetY: 20,
    blurRadius: 22,
    opacity: 0.7,
    darkness: 0.6,
  );
}
