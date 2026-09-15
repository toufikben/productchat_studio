import '../models/recipe.dart';
import 'ai_service.dart';
import 'ai/relight_service.dart';
import 'ai/colorize_service.dart';
import 'compliance_service.dart';
import 'watermark_service.dart';

/// RecipeRunnerService — ينفذ سلسلة عمليات Recipe بالكامل.
class RecipeRunnerService {
  final _border = BorderCutService();
  final _shadow = ShadowService();
  final _enhance = BasicEnhanceService();
  final _relight = RelightService();
  final _colorize = ColorizeService();
  final _export = ExportService();
  final _watermark = WatermarkService();

  Future<RecipeResult> run(
    Recipe recipe,
    String inputPath, {
    Function(String step, double progress)? onProgress,
  }) async {
    final sw = Stopwatch()..start();
    String currentPath = inputPath;
    final steps = <RecipeStep>[];

    try {
      // ─── Step 1: Remove BG ───
      if (recipe.steps['removeBg'] == true) {
        onProgress?.call('Removing background', 0.2);
        final r = await _border.removeBg(currentPath);
        if (!r.ok) throw Exception('BG removal failed: ${r.error}');
        currentPath = r.outputPath!;
        steps.add(RecipeStep('removeBg', true));
      }

      // ─── Step 2: Enhance ───
      if (recipe.steps['enhance'] == true) {
        onProgress?.call('Enhancing', 0.4);
        final factor = (recipe.steps['factor'] as int?) ?? 2;
        final r = await _enhance.enhance(currentPath, factor: factor);
        if (r.ok) currentPath = r.outputPath!;
        steps.add(RecipeStep('enhance', r.ok));
      }

      // ─── Step 3: Shadow ───
      if (recipe.steps['shadow'] != null) {
        onProgress?.call('Adding shadow', 0.5);
        final r = await _shadow.addShadow(
          currentPath,
          type: recipe.steps['shadow'] as String? ?? 'natural',
        );
        if (r.ok) currentPath = r.outputPath!;
        steps.add(RecipeStep('shadow', r.ok));
      }

      // ─── Step 4: Relight ───
      if (recipe.steps['relight'] != null) {
        onProgress?.call('Relighting', 0.6);
        final r = await _relight.relight(
          currentPath,
          style: recipe.steps['relight'] as String? ?? 'studio',
        );
        if (r.ok) currentPath = r.outputPath!;
        steps.add(RecipeStep('relight', r.ok));
      }

      // ─── Step 5: Watermark (free users) ───
      if (recipe.steps['watermark'] == true) {
        onProgress?.call('Adding watermark', 0.7);
        currentPath = await _watermark.apply(currentPath);
        steps.add(const RecipeStep('watermark', true));
      }

      // ─── Step 6: Export ───
      onProgress?.call('Exporting', 0.9);
      final size = (recipe.steps['size'] as int?) ?? 2048;
      final format = (recipe.steps['format'] as String?) ?? 'jpg';
      final out = await _export.export(currentPath, format: format, size: size);
      currentPath = out.path;
      steps.add(const RecipeStep('export', true));

      onProgress?.call('Done', 1.0);

      return RecipeResult(
        ok: true,
        outputPath: currentPath,
        steps: steps,
        duration: sw.elapsed,
      );
    } catch (e) {
      return RecipeResult(
        ok: false,
        outputPath: currentPath,
        steps: steps,
        duration: sw.elapsed,
        error: '$e',
      );
    }
  }
}

class RecipeStep {
  final String name;
  final bool ok;
  const RecipeStep(this.name, this.ok);
}

class RecipeResult {
  final bool ok;
  final String outputPath;
  final List<RecipeStep> steps;
  final Duration duration;
  final String? error;
  const RecipeResult({
    required this.ok,
    required this.outputPath,
    required this.steps,
    required this.duration,
    this.error,
  });
}
