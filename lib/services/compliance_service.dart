import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import '../models/platform_spec.dart';

// ═══════════════════════════════════════════════════════════════
// Compliance Result
// ═══════════════════════════════════════════════════════════════
class ComplianceResult {
  final bool passed;
  final List<ComplianceIssue> issues;
  final Map<String, dynamic> metadata;
  const ComplianceResult({
    required this.passed,
    required this.issues,
    this.metadata = const {},
  });
}

class ComplianceIssue {
  final String code;
  final String message;
  final String severity; // 'error' | 'warning' | 'info'
  final String? fix;
  const ComplianceIssue({
    required this.code,
    required this.message,
    required this.severity,
    this.fix,
  });
}

// ═══════════════════════════════════════════════════════════════
// Compliance Service (Real implementation)
// ═══════════════════════════════════════════════════════════════
class ComplianceService {
  Future<ComplianceResult> check(String imagePath, PlatformSpec spec) async {
    final issues = <ComplianceIssue>[];
    final bytes = await File(imagePath).readAsBytes();
    final im = img.decodeImage(bytes);
    if (im == null) {
      return const ComplianceResult(
        passed: false,
        issues: [
          ComplianceIssue(
              code: 'DECODE',
              message: 'Failed to decode image',
              severity: 'error'),
        ],
      );
    }

    final fileSize = await File(imagePath).length();

    // ─── 1. Dimensions ───
    if (im.width < spec.minSize || im.height < spec.minSize) {
      issues.add(ComplianceIssue(
        code: 'DIMENSIONS',
        message:
            'Current: ${im.width}×${im.height}. Required ≥${spec.minSize}px.',
        severity: 'error',
        fix: 'Resize to ${spec.recommendedSize}×${spec.recommendedSize}',
      ));
    } else if (im.width < spec.recommendedSize ||
        im.height < spec.recommendedSize) {
      issues.add(ComplianceIssue(
        code: 'DIMENSIONS_SUBOPTIMAL',
        message: 'Recommended: ${spec.recommendedSize}px.',
        severity: 'warning',
        fix: 'Upscale to ${spec.recommendedSize}×${spec.recommendedSize}',
      ));
    }

    // ─── 2. Aspect ratio ───
    if (spec.squareOnly && im.width != im.height) {
      issues.add(const ComplianceIssue(
        code: 'NOT_SQUARE',
        message: 'Square (1:1) aspect ratio preferred.',
        severity: 'warning',
        fix: 'Crop to square',
      ));
    }

    // ─── 3. Background color ───
    if (spec.bgHex == '#FFFFFF') {
      final corners = [
        im.getPixel(5, 5),
        im.getPixel(im.width - 6, 5),
        im.getPixel(5, im.height - 6),
        im.getPixel(im.width - 6, im.height - 6),
      ];
      final isWhite = corners.every((p) => p.r > 250 && p.g > 250 && p.b > 250);
      if (!isWhite) {
        issues.add(const ComplianceIssue(
          code: 'BG_NOT_WHITE',
          message: 'Background is not pure white (255,255,255).',
          severity: 'error',
          fix: 'Remove or replace background',
        ));
      }
    }

    // ─── 4. Product coverage (Amazon only) ───
    if (spec.name == 'Amazon') {
      final cov = _coverage(im);
      if (cov < 0.85) {
        issues.add(ComplianceIssue(
          code: 'LOW_COVERAGE',
          message:
              'Product fills ${(cov * 100).toStringAsFixed(0)}%. Amazon requires 85%+.',
          severity: 'warning',
          fix: 'Crop closer or enlarge product',
        ));
      }
    }

    // ─── 5. File size ───
    final sizeMB = fileSize / (1024 * 1024);
    if (sizeMB > 10) {
      issues.add(ComplianceIssue(
        code: 'FILE_SIZE',
        message: 'File is ${sizeMB.toStringAsFixed(1)} MB. Recommended <10 MB.',
        severity: 'warning',
        fix: 'Compress image',
      ));
    }

    // ─── 6. Format ───
    final ext = imagePath.split('.').last.toLowerCase();
    if (spec.format == 'jpg' && ext != 'jpg' && ext != 'jpeg') {
      issues.add(ComplianceIssue(
        code: 'FORMAT',
        message:
            'Expected format: ${spec.format.toUpperCase()}, got: ${ext.toUpperCase()}.',
        severity: 'warning',
        fix: 'Export as ${spec.format.toUpperCase()}',
      ));
    }

    // ─── 7. Transparent background check (PNG) ───
    if (ext == 'png' && spec.bgHex == '#FFFFFF') {
      final hasAlpha = im.numChannels == 4;
      if (hasAlpha) {
        var alphaCount = 0;
        var total = 0;
        for (var y = 0; y < im.height; y += 10) {
          for (var x = 0; x < im.width; x += 10) {
            if (im.getPixel(x, y).a < 255) alphaCount++;
            total++;
          }
        }
        if (alphaCount / total > 0.1) {
          issues.add(const ComplianceIssue(
            code: 'TRANSPARENT_BG',
            message:
                'PNG has transparent areas — not compatible with white BG requirement.',
            severity: 'warning',
            fix: 'Flatten with white background',
          ));
        }
      }
    }

    return ComplianceResult(
      passed: issues.where((i) => i.severity == 'error').isEmpty,
      issues: issues,
      metadata: {
        'width': im.width,
        'height': im.height,
        'fileSize': fileSize,
        'format': ext,
        'platform': spec.name,
      },
    );
  }

  double _coverage(img.Image im) {
    final bg = _avgCorners(im);
    final visited = Uint8List(im.width * im.height);
    final queue = <int>[];
    for (var x = 0; x < im.width; x++) {
      queue.add(x);
      queue.add((im.height - 1) * im.width + x);
    }
    for (var y = 0; y < im.height; y++) {
      queue.add(y * im.width);
      queue.add(y * im.width + im.width - 1);
    }
    var head = 0, bgCount = 0;
    final maxIter = im.width * im.height ~/ 2;
    while (head < queue.length && bgCount < maxIter) {
      final idx = queue[head++];
      if (visited[idx] == 1) continue;
      visited[idx] = 1;
      final x = idx % im.width;
      final y = idx ~/ im.width;
      final p = im.getPixel(x, y);
      if (_dist(p.r, p.g, p.b, bg[0], bg[1], bg[2]) > 60) continue;
      bgCount++;
      if (x > 0) queue.add(idx - 1);
      if (x < im.width - 1) queue.add(idx + 1);
      if (y > 0) queue.add(idx - im.width);
      if (y < im.height - 1) queue.add(idx + im.width);
    }
    return 1.0 - (bgCount / (im.width * im.height));
  }

  List<int> _avgCorners(img.Image im) {
    final pts = [
      im.getPixel(5, 5),
      im.getPixel(im.width - 6, 5),
      im.getPixel(5, im.height - 6),
      im.getPixel(im.width - 6, im.height - 6),
    ];
    var r = 0, g = 0, b = 0;
    for (final p in pts) {
      r += p.r.toInt();
      g += p.g.toInt();
      b += p.b.toInt();
    }
    return [r ~/ 4, g ~/ 4, b ~/ 4];
  }

  double _dist(num r1, num g1, num b1, int r2, int g2, int b2) {
    final dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
    return (dr * dr + dg * dg + db * db) / 1000.0;
  }
}

// ═══════════════════════════════════════════════════════════════
// Export Service (Complete)
// ═══════════════════════════════════════════════════════════════
class ExportService {
  Future<File> export(
    String inputPath, {
    required String format,
    int? size,
    int quality = 92,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    var im = img.decodeImage(bytes)!;
    if (size != null) {
      im = img.copyResize(im, width: size, height: size, maintainAspect: false);
    }

    final tempPath = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_tmp.jpg');
    await File(tempPath).writeAsBytes(img.encodeJpg(im, quality: 95));

    final outPath = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_out.$format');
    final compressFormat = switch (format) {
      'png' => CompressFormat.png,
      'webp' => CompressFormat.webp,
      'heic' => CompressFormat.heic,
      _ => CompressFormat.jpeg,
    };

    await FlutterImageCompress.compressAndGetFile(
      tempPath,
      outPath,
      format: compressFormat,
      quality: quality,
      minWidth: size ?? im.width,
      minHeight: size ?? im.height,
    );
    await File(tempPath).delete();
    return File(outPath);
  }

  Future<List<File>> batchExport(
    List<String> inputs, {
    required String format,
    int? size,
  }) async {
    final results = <File>[];
    for (final p in inputs) {
      results.add(await export(p, format: format, size: size));
    }
    return results;
  }
}
