import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/edit_request.dart';
import '../models/platform_spec.dart';

/// Performs lightweight, on-device image inspection and returns ranked actions.
class SmartAnalysisService {
  Future<AnalysisResult> analyze(String imagePath, {PlatformSpec? targetPlatform}) async {
    try {
      final image = img.decodeImage(await File(imagePath).readAsBytes());
      if (image == null) return const AnalysisResult(ok: false, error: 'Failed to decode image', suggestions: []);
      final brightness = _averageBrightness(image);
      final complexity = _backgroundComplexity(image);
      final coverage = _productCoverage(image);
      final suggestions = <Suggestion>[];
      if (brightness < 90) suggestions.add(Suggestion('dark_image', 'Image is dark', 'Enhance lighting?', 'brightness_6', EditOp.relight, 90));
      if (brightness > 220) suggestions.add(Suggestion('overexposed', 'Image is overexposed', 'Reduce highlights?', 'brightness_4', EditOp.relight, 80));
      if (image.width < 1000 || image.height < 1000) suggestions.add(Suggestion('low_resolution', 'Low resolution', 'Upscale 2×?', 'high_quality', EditOp.enhance, 95));
      if (complexity > .3) suggestions.add(Suggestion('complex_bg', 'Complex background detected', 'Remove background?', 'content_cut', EditOp.removeBg, 100));
      if (complexity < .05) suggestions.add(Suggestion('solid_bg', 'Solid background detected', 'Fast background removal available.', 'auto_fix_high', EditOp.removeBg, 70));
      if (!_detectShadow(image) && complexity < .3) suggestions.add(Suggestion('no_shadow', 'No shadow detected', 'Add a realistic shadow?', 'brightness_4', EditOp.shadow, 60));
      if (coverage < .4) suggestions.add(Suggestion('small_product', 'Product appears small', 'Crop closer?', 'crop', EditOp.export, 65));
      if (targetPlatform != null && (image.width < targetPlatform.minSize || image.height < targetPlatform.minSize)) suggestions.add(Suggestion('platform_size', 'Not ready for ${targetPlatform.name}', 'Upscale before export.', 'verified', EditOp.export, 100));
      if (image.width / image.height < .9 || image.width / image.height > 1.1) suggestions.add(Suggestion('aspect_ratio', 'Non-square aspect ratio', 'Square (1:1) is preferred.', 'aspect_ratio', EditOp.export, 55));
      suggestions.sort((a, b) => b.priority.compareTo(a.priority));
      return AnalysisResult(ok: true, suggestions: suggestions.take(5).toList(), metadata: {'width': image.width, 'height': image.height, 'brightness': brightness.round(), 'bg_complexity': complexity, 'coverage': coverage});
    } catch (e) { return AnalysisResult(ok: false, error: '$e', suggestions: []); }
  }
  double _averageBrightness(img.Image im) { var sum = 0.0; var count = 0; final step = math.max(1, math.min(im.width, im.height) ~/ 100); for (var y = 0; y < im.height; y += step) { for (var x = 0; x < im.width; x += step) { final p = im.getPixel(x, y); sum += .299 * p.r + .587 * p.g + .114 * p.b; count++; }} return count == 0 ? 0 : sum / count; }
  double _backgroundComplexity(img.Image im) { final samples = <List<int>>[]; final step = math.max(1, math.min(im.width, im.height) ~/ 50); for (var x = 0; x < im.width; x += step) { for (final y in [math.min(5, im.height - 1), math.max(0, im.height - 6)]) { final p = im.getPixel(x, y); samples.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]); }} if (samples.isEmpty) return 0; final mean = List<double>.generate(3, (i) => samples.map((s) => s[i]).reduce((a, b) => a + b) / samples.length); var variance = 0.0; for (final s in samples) { for (var i = 0; i < 3; i++) variance += math.pow(s[i] - mean[i], 2); } return math.sqrt(variance / (samples.length * 3)) / 128; }
  bool _detectShadow(img.Image im) { final start = (im.height * 2) ~/ 3; var dark = 0; var total = 0; final step = math.max(1, im.height ~/ 100); for (var y = start; y < im.height; y += step) { for (var x = 0; x < im.width; x += step) { final p = im.getPixel(x, y); if (.299 * p.r + .587 * p.g + .114 * p.b < 100) dark++; total++; }} return total > 0 && dark / total > .15; }
  double _productCoverage(img.Image im) { if (im.width < 2 || im.height < 2) return 0; final b = im.getPixel(0, 0); var product = 0; var total = 0; final step = math.max(1, im.width ~/ 50); for (var y = 0; y < im.height; y += step) for (var x = 0; x < im.width; x += step) { final p = im.getPixel(x, y); final d = math.sqrt(math.pow(p.r - b.r, 2) + math.pow(p.g - b.g, 2) + math.pow(p.b - b.b, 2)); if (d > 60) product++; total++; } return total == 0 ? 0 : product / total; }
}
class Suggestion { final String id, title, description, icon; final EditOp op; final int priority; const Suggestion(this.id, this.title, this.description, this.icon, this.op, this.priority); }
class AnalysisResult { final bool ok; final String? error; final List<Suggestion> suggestions; final Map<String, dynamic> metadata; const AnalysisResult({required this.ok, this.error, required this.suggestions, this.metadata = const {}}); }
