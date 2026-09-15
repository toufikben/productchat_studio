import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// ProductFidelityService — Compares before/after images to detect
/// color/shape deviations in the product (fidelity check).
class ProductFidelityService {
  Future<FidelityResult> check({
    required String originalPath,
    required String editedPath,
    double threshold = 0.15,
  }) async {
    try {
      final origBytes = await File(originalPath).readAsBytes();
      final editBytes = await File(editedPath).readAsBytes();
      final orig = img.decodeImage(origBytes);
      final edit = img.decodeImage(editBytes);
      if (orig == null || edit == null) {
        return const FidelityResult(passed: false, score: 0.0, deviations: []);
      }

      // ─── Analyze color histogram ───
      final origColor = _avgColor(orig);
      final editColor = _avgColor(edit);

      final colorDelta = _colorDistance(origColor, editColor) / 255.0;

      // ─── Analyze shape (product coverage) ───
      final origCoverage = _coverage(orig);
      final editCoverage = _coverage(edit);
      final coverageDelta = (origCoverage - editCoverage).abs();

      // ─── Analyze luminance ───
      final origLum = _avgLuminance(orig);
      final editLum = _avgLuminance(edit);
      final lumDelta = (origLum - editLum).abs() / 255.0;

      // ─── Score ───
      final score = 1.0 - ((colorDelta + coverageDelta + lumDelta) / 3.0);
      final deviations = <FidelityDeviation>[];

      if (colorDelta > threshold) {
        deviations.add(FidelityDeviation(
          type: 'color',
          message: 'Color shift detected: ${(colorDelta * 100).toStringAsFixed(0)}%',
          severity: colorDelta > 0.3 ? 'high' : 'medium',
        ));
      }
      if (coverageDelta > threshold) {
        deviations.add(FidelityDeviation(
          type: 'shape',
          message: 'Product shape changed: ${(coverageDelta * 100).toStringAsFixed(0)}%',
          severity: coverageDelta > 0.3 ? 'high' : 'medium',
        ));
      }
      if (lumDelta > threshold) {
        deviations.add(FidelityDeviation(
          type: 'lighting',
          message: 'Lighting shift: ${(lumDelta * 100).toStringAsFixed(0)}%',
          severity: lumDelta > 0.3 ? 'high' : 'medium',
        ));
      }

      return FidelityResult(
        passed: score > 0.7,
        score: score,
        deviations: deviations,
      );
    } catch (e) {
      return FidelityResult(passed: false, score: 0.0, deviations: []);
    }
  }

  List<int> _avgColor(img.Image im) {
    var r = 0, g = 0, b = 0, count = 0;
    final step = math.max(1, (im.width * im.height) ~/ 1000);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        final p = im.getPixel(x, y);
        r += p.r.toInt(); g += p.g.toInt(); b += p.b.toInt();
        count++;
      }
    }
    return [r ~/ count, g ~/ count, b ~/ count];
  }

  double _colorDistance(List<int> a, List<int> b) {
    final dr = a[0] - b[0], dg = a[1] - b[1], db = a[2] - b[2];
    return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
  }

  double _coverage(img.Image im) {
    final corner = im.getPixel(5, 5);
    var productPixels = 0, total = 0;
    final step = math.max(1, im.width ~/ 50);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        final p = im.getPixel(x, y);
        final d = math.sqrt(
          math.pow(p.r - corner.r, 2) +
          math.pow(p.g - corner.g, 2) +
          math.pow(p.b - corner.b, 2),
        );
        if (d > 60) productPixels++;
        total++;
      }
    }
    return total > 0 ? productPixels / total : 0.0;
  }

  double _avgLuminance(img.Image im) {
    var sum = 0.0, count = 0;
    final step = math.max(1, (im.width * im.height) ~/ 1000);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        final p = im.getPixel(x, y);
        sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }
}

class FidelityResult {
  final bool passed;
  final double score;
  final List<FidelityDeviation> deviations;
  const FidelityResult({
    required this.passed,
    required this.score,
    required this.deviations,
  });
}

class FidelityDeviation {
  final String type;
  final String message;
  final String severity;
  const FidelityDeviation({
    required this.type,
    required this.message,
    required this.severity,
  });
}
