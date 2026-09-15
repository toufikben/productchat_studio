// تم نقل الخدمات الفرعية إلى lib/services/ai/

// Re-exports for backward compatibility
export 'ai/migan_service.dart';
export 'ai/qwen_edit_service.dart';
export 'ai/relight_service.dart';
export 'ai/colorize_service.dart';
export 'model_manager.dart';

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../models/edit_request.dart';

// ═══════════════════════════════════════════════════════════════
// BorderCutService (0MB PatchMatch)
// ═══════════════════════════════════════════════════════════════
class BorderCutService {
  static const _channel = MethodChannel('com.productchat/seika');

  Future<EditResult> removeBg(String inputPath) async {
    final sw = Stopwatch()..start();
    try {
      final out = await _channel.invokeMapMethod<String, dynamic>('removeBg', {
        'path': inputPath,
        'quality': 'fast',
      });
      if (out == null || out['ok'] != true) {
        return EditResult(
            ok: false, error: out?['error']?.toString() ?? 'Failed');
      }
      return EditResult(
        ok: true,
        outputPath: out['outputPath'] as String,
        creditsUsed: 1,
        duration: sw.elapsed,
      );
    } on PlatformException catch (e) {
      return EditResult(ok: false, error: '${e.code}: ${e.message}');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// SeikaService (LaMa — Best quality)
// ═══════════════════════════════════════════════════════════════
class SeikaService {
  static const _channel = MethodChannel('com.productchat/seika');
  final String quality;
  SeikaService({this.quality = 'best'});

  Future<EditResult> removeBg(String inputPath) async {
    final sw = Stopwatch()..start();
    try {
      final out = await _channel.invokeMapMethod<String, dynamic>('removeBg', {
        'path': inputPath,
        'quality': quality,
      });
      if (out == null || out['ok'] != true) {
        return EditResult(
            ok: false, error: out?['error']?.toString() ?? 'Failed');
      }
      return EditResult(
        ok: true,
        outputPath: out['outputPath'] as String,
        creditsUsed: 3,
        duration: sw.elapsed,
      );
    } on PlatformException catch (e) {
      return EditResult(ok: false, error: '${e.code}: ${e.message}');
    }
  }

  Future<EditResult> inpaint(String imagePath, String maskPath) async {
    try {
      final out = await _channel.invokeMapMethod<String, dynamic>('inpaint', {
        'path': imagePath,
        'maskPath': maskPath,
      });
      return EditResult(
        ok: out?['ok'] == true,
        outputPath: out?['outputPath'] as String?,
        creditsUsed: 3,
      );
    } on PlatformException catch (e) {
      return EditResult(ok: false, error: e.message);
    }
  }

  /// Compatibility API for older controllers that expose upscale through Seika.
  bool get isUpscaleReady => false;

  Future<EditResult> upscale(String inputPath, {int factor = 2}) async {
    return const EditResult(
      ok: false,
      error: 'Upscale model is not available through the Seika bridge.',
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BasicEnhanceService (Lanczos + Unsharp)
// ═══════════════════════════════════════════════════════════════
class BasicEnhanceService {
  Future<EditResult> enhance(
    String inputPath, {
    int factor = 2,
    bool sharpen = true,
    bool denoise = false,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null)
        return const EditResult(ok: false, error: 'Decode failed');

      var out = img.copyResize(
        src,
        width: src.width * factor,
        height: src.height * factor,
        interpolation: img.Interpolation.cubic,
      );

      if (sharpen) out = _unsharp(out, amount: 0.5, radius: 1);
      if (denoise) {
        out = img.gaussianBlur(out, radius: 1);
        if (sharpen) out = _unsharp(out, amount: 0.3, radius: 1);
      }

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_enhanced.png');
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

  img.Image _unsharp(img.Image src,
      {required double amount, required int radius}) {
    final blurred = img.gaussianBlur(src, radius: radius);
    final out = img.Image(width: src.width, height: src.height, numChannels: 3);
    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final s = src.getPixel(x, y);
        final b = blurred.getPixel(x, y);
        out.setPixelRgb(
          x,
          y,
          (s.r + amount * (s.r - b.r)).round().clamp(0, 255),
          (s.g + amount * (s.g - b.g)).round().clamp(0, 255),
          (s.b + amount * (s.b - b.b)).round().clamp(0, 255),
        );
      }
    }
    return out;
  }
}

// ═══════════════════════════════════════════════════════════════
// ShadowService (Pure Dart — 3 types)
// ═══════════════════════════════════════════════════════════════
class ShadowService {
  Future<EditResult> addShadow(
    String inputPath, {
    String type = 'natural',
    double intensity = 0.35,
  }) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null)
        return const EditResult(ok: false, error: 'Decode failed');

      final (blurRadius, dx, dy) = switch (type) {
        'hard' => (3, 6, 6),
        'natural' => (18, 10, 14),
        _ => (12, 6, 8),
      };

      final alpha = _extractAlpha(src);
      final shifted = _shift(alpha, src.width, src.height, dx, dy);
      final blurred = _blur(shifted, src.width, src.height, blurRadius);

      final out =
          img.Image(width: src.width, height: src.height, numChannels: 4);
      for (var y = 0; y < src.height; y++) {
        for (var x = 0; x < src.width; x++) {
          final sp = src.getPixel(x, y);
          final sA = blurred[y * src.width + x];
          final scaled = (sA * intensity).round().clamp(0, 255);
          final factor = 1.0 - (scaled / 255.0) * 0.6;
          out.setPixelRgba(
            x,
            y,
            (sp.r * factor).round().clamp(0, 255),
            (sp.g * factor).round().clamp(0, 255),
            (sp.b * factor).round().clamp(0, 255),
            math.max(sp.a.toInt(), scaled),
          );
        }
      }
      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_shadow.png');
      await File(path).writeAsBytes(img.encodePng(out));
      return EditResult(ok: true, outputPath: path, creditsUsed: 1);
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }

  Uint8List _extractAlpha(img.Image im) {
    final a = Uint8List(im.width * im.height);
    for (var y = 0; y < im.height; y++) {
      for (var x = 0; x < im.width; x++) {
        a[y * im.width + x] = im.getPixel(x, y).a.toInt();
      }
    }
    return a;
  }

  Uint8List _shift(Uint8List src, int w, int h, int dx, int dy) {
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final sx = x - dx, sy = y - dy;
        if (sx >= 0 && sx < w && sy >= 0 && sy < h) {
          out[y * w + x] = src[sy * w + sx];
        }
      }
    }
    return out;
  }

  Uint8List _blur(Uint8List src, int w, int h, int radius) {
    if (radius <= 0) return src;
    var cur = src;
    for (var i = 0; i < 3; i++) {
      cur = _boxBlur(cur, w, h, radius);
    }
    return cur;
  }

  Uint8List _boxBlur(Uint8List src, int w, int h, int r) {
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var sum = 0, count = 0;
        for (var dy = -r; dy <= r; dy++) {
          for (var dx = -r; dx <= r; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
              sum += src[ny * w + nx];
              count++;
            }
          }
        }
        out[y * w + x] = (sum / count).round().clamp(0, 255);
      }
    }
    return out;
  }
}

// ═══════════════════════════════════════════════════════════════
// UpscaleService (Real-ESRGAN wrapper)
// ═══════════════════════════════════════════════════════════════
class UpscaleService {
  static const _channel = MethodChannel('com.productchat/seika');

  Future<EditResult> upscale(String inputPath, {int factor = 2}) async {
    final sw = Stopwatch()..start();
    try {
      final out = await _channel.invokeMapMethod<String, dynamic>('upscale', {
        'path': inputPath,
        'factor': factor,
      });
      if (out == null || out['ok'] != true) {
        return EditResult(
            ok: false, error: out?['error']?.toString() ?? 'Failed');
      }
      return EditResult(
        ok: true,
        outputPath: out['outputPath'] as String,
        creditsUsed: 2,
        duration: sw.elapsed,
      );
    } on PlatformException catch (e) {
      return EditResult(ok: false, error: '${e.code}: ${e.message}');
    }
  }
}

/// Stable facade used by controllers and contract tests.
class AiService {
  final BorderCutService _border = BorderCutService();
  final BasicEnhanceService _enhance = BasicEnhanceService();
  final ShadowService _shadow = ShadowService();

  Future<EditResult> apply(String imagePath, EditOp op,
      {String? maskPath}) async {
    if (imagePath.trim().isEmpty) {
      return const EditResult.failure('Invalid image path');
    }
    if (op == EditOp.relight ||
        op == EditOp.inpaint ||
        op == EditOp.conversational) {
      if (maskPath == null || maskPath.trim().isEmpty) {
        return const EditResult.failure(
            'A mask is required for this operation');
      }
    }
    switch (op) {
      case EditOp.removeBg:
        return _border.removeBg(imagePath);
      case EditOp.enhance:
        return _enhance.enhance(imagePath, factor: 2);
      case EditOp.shadow:
        return _shadow.addShadow(imagePath);
      default:
        return const EditResult.failure(
            'Operation is not available through AiService');
    }
  }
}
