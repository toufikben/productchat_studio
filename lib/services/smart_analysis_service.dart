import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/edit_request.dart';
import '../models/platform_spec.dart';

/// Performs lightweight, on-device image inspection and returns ranked actions.
///
/// Fix (2026-09-15): [_productCoverage] previously sampled only the top-left
/// pixel (0, 0) as the background reference, which misidentified the product
/// as background when the image was bleed-to-edge. The corrected version
/// samples the four corners and uses the median colour as the background
/// reference, which is robust against products that overlap any single corner.
class SmartAnalysisService {
  Future<AnalysisResult> analyze(String imagePath,
      {PlatformSpec? targetPlatform}) async {
    try {
      final image = img.decodeImage(await File(imagePath).readAsBytes());
      if (image == null) {
        return const AnalysisResult(
          ok: false,
          error: 'Failed to decode image',
          suggestions: [],
        );
      }
      final brightness = _averageBrightness(image);
      final complexity = _backgroundComplexity(image);
      final coverage = _productCoverage(image);
      final suggestions = <Suggestion>[];
      if (brightness < 90) {
        suggestions.add(const Suggestion('dark_image', 'Image is dark',
            'Enhance lighting?', 'brightness_6', EditOp.relight, 90));
      }
      if (brightness > 220) {
        suggestions.add(const Suggestion('overexposed', 'Image is overexposed',
            'Reduce highlights?', 'brightness_4', EditOp.relight, 80));
      }
      if (image.width < 1000 || image.height < 1000) {
        suggestions.add(const Suggestion('low_resolution', 'Low resolution',
            'Upscale 2\u00d7?', 'high_quality', EditOp.enhance, 95));
      }
      if (complexity > .3) {
        suggestions.add(const Suggestion(
            'complex_bg',
            'Complex background detected',
            'Remove background?',
            'content_cut',
            EditOp.removeBg,
            100));
      } else if (complexity < .05) {
        suggestions.add(const Suggestion(
            'solid_bg',
            'Solid background detected',
            'Fast background removal available.',
            'auto_fix_high',
            EditOp.removeBg,
            70));
      }
      if (!_detectShadow(image) && complexity < .3) {
        suggestions.add(const Suggestion('no_shadow', 'No shadow detected',
            'Add a realistic shadow?', 'brightness_4', EditOp.shadow, 60));
      }
      if (coverage < .4) {
        suggestions.add(const Suggestion('small_product', 'Product appears small',
            'Crop closer?', 'crop', EditOp.export, 65));
      }
      if (targetPlatform != null &&
          (image.width < targetPlatform.minSize ||
              image.height < targetPlatform.minSize)) {
        suggestions.add(Suggestion(
            'platform_size',
            'Not ready for \${targetPlatform.name}',
            'Upscale before export.',
            'verified',
            EditOp.export,
            100));
      }
      final ratio = image.width / image.height;
      if (ratio < .9 || ratio > 1.1) {
        suggestions.add(const Suggestion('aspect_ratio',
            'Non-square aspect ratio', 'Square (1:1) is preferred.',
            'aspect_ratio', EditOp.export, 55));
      }
      suggestions.sort((a, b) => b.priority.compareTo(a.priority));
      return AnalysisResult(
        ok: true,
        suggestions: suggestions.take(5).toList(),
        metadata: {
          'width': image.width,
          'height': image.height,
          'brightness': brightness.round(),
          'bg_complexity': complexity,
          'coverage': coverage,
        },
      );
    } catch (e) {
      return AnalysisResult(ok: false, error: '\$e', suggestions: []);
    }
  }

  double _averageBrightness(img.Image image) {
    var sum = 0.0;
    var count = 0;
    final step = math.max(1, math.min(image.width, image.height) ~/ 100);
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        sum += .299 * pixel.r + .587 * pixel.g + .114 * pixel.b;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }

  double _backgroundComplexity(img.Image image) {
    final samples = <List<int>>[];
    final step = math.max(1, math.min(image.width, image.height) ~/ 50);
    for (var x = 0; x < image.width; x += step) {
      for (final y in [
        math.min(5, image.height - 1),
        math.max(0, image.height - 6)
      ]) {
        final pixel = image.getPixel(x, y);
        samples.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      }
    }
    if (samples.isEmpty) return 0;
    final mean = List<double>.generate(
        3,
        (i) =>
            samples.map((s) => s[i]).reduce((a, b) => a + b) /
            samples.length);
    var variance = 0.0;
    for (final sample in samples) {
      for (var i = 0; i < 3; i++) {
        variance += math.pow(sample[i] - mean[i], 2);
      }
    }
    return math.sqrt(variance / (samples.length * 3)) / 128;
  }

  bool _detectShadow(img.Image image) {
    final start = (image.height * 2) ~/ 3;
    var dark = 0;
    var total = 0;
    final step = math.max(1, image.height ~/ 100);
    for (var y = start; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        if (.299 * pixel.r + .587 * pixel.g + .114 * pixel.b < 100) {
          dark++;
        }
        total++;
      }
    }
    return total > 0 && dark / total > .15;
  }

  /// Estimates how much of the image is occupied by the product (non-background
  /// pixels).
  ///
  /// Previous implementation: sampled only pixel (0, 0) as the background
  /// reference colour. This caused false negatives when the product extended to
  /// the top-left corner — the corner pixel was the product colour, so almost
  /// every sampled pixel appeared to be "not background".
  ///
  /// Fix: sample all four corners and use a per-channel median as the
  /// background reference. This is more robust when one corner is occupied by
  /// the product, while still being O(1) in the number of reference samples.
  double _productCoverage(img.Image image) {
    if (image.width < 2 || image.height < 2) return 0;

    // Sample the four corners to derive a background reference colour.
    final corners = [
      image.getPixel(0, 0),
      image.getPixel(image.width - 1, 0),
      image.getPixel(0, image.height - 1),
      image.getPixel(image.width - 1, image.height - 1),
    ];
    final rs = corners.map((p) => p.r.toDouble()).toList()..sort();
    final gs = corners.map((p) => p.g.toDouble()).toList()..sort();
    final bs = corners.map((p) => p.b.toDouble()).toList()..sort();
    // Median of four values = average of middle two.
    final bgR = (rs[1] + rs[2]) / 2;
    final bgG = (gs[1] + gs[2]) / 2;
    final bgB = (bs[1] + bs[2]) / 2;

    var product = 0;
    var total = 0;
    final step = math.max(1, image.width ~/ 50);
    for (var y = 0; y < image.height; y += step) {
      for (var x = 0; x < image.width; x += step) {
        final pixel = image.getPixel(x, y);
        final distance = math.sqrt(
            math.pow(pixel.r - bgR, 2) +
            math.pow(pixel.g - bgG, 2) +
            math.pow(pixel.b - bgB, 2));
        if (distance > 60) product++;
        total++;
      }
    }
    return total == 0 ? 0 : product / total;
  }
}

class Suggestion {
  final String id;
  final String title;
  final String description;
  final String icon;
  final EditOp op;
  final int priority;

  const Suggestion(this.id, this.title, this.description, this.icon, this.op,
      this.priority);
}

class AnalysisResult {
  final bool ok;
  final String? error;
  final List<Suggestion> suggestions;
  final Map<String, dynamic> metadata;

  const AnalysisResult({
    required this.ok,
    this.error,
    required this.suggestions,
    this.metadata = const {},
  });
}
