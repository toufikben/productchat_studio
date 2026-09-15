import '../models/edit_request.dart';
import 'ai_service.dart';
import 'ai/relight_service.dart';
import 'filters_service.dart';

enum EnhancePreset {
  auto,
  productStudio,
  marketplaceHero,
  instagramReady,
  softProduct,
  highContrast,
  warmCommerce,
  cleanWhite,
}

/// EnhancementPresetsService — One-tap enhancements with preset combinations.
class EnhancementPresetsService {
  final _enhance = BasicEnhanceService();
  final _relight = RelightService();
  final _filters = FiltersService();

  Future<EditResult> apply(String inputPath, EnhancePreset preset) async {
    final sw = Stopwatch()..start();
    String currentPath = inputPath;

    try {
      switch (preset) {
        case EnhancePreset.auto:
          final r_auto = await _enhance.enhance(currentPath, factor: 2, sharpen: true);
          if (r_auto.ok) currentPath = r_auto.outputPath!;
          final r2_auto = await _filters.apply(currentPath, preset: FilterPreset.vivid, intensity: 0.3);
          if (r2_auto.ok) currentPath = r2_auto.outputPath!;
          break;

        case EnhancePreset.productStudio:
          final r_studio = await _relight.relight(currentPath, style: 'studio', intensity: 1.05);
          if (r_studio.ok) currentPath = r_studio.outputPath!;
          final r2_studio = await _filters.apply(currentPath, preset: FilterPreset.vivid, intensity: 0.4);
          if (r2_studio.ok) currentPath = r2_studio.outputPath!;
          break;

        case EnhancePreset.marketplaceHero:
          final r_marketplace = await _enhance.enhance(currentPath, factor: 2, sharpen: true);
          if (r_marketplace.ok) currentPath = r_marketplace.outputPath!;
          final r2_marketplace = await _filters.apply(currentPath, preset: FilterPreset.matte, intensity: 0.2);
          if (r2_marketplace.ok) currentPath = r2_marketplace.outputPath!;
          break;

        case EnhancePreset.instagramReady:
          final r_instagram = await _filters.apply(currentPath, preset: FilterPreset.cinematic, intensity: 0.5);
          if (r_instagram.ok) currentPath = r_instagram.outputPath!;
          break;

        case EnhancePreset.softProduct:
          final r_soft = await _relight.relight(currentPath, style: 'natural', intensity: 1.02);
          if (r_soft.ok) currentPath = r_soft.outputPath!;
          final r2_soft = await _filters.apply(currentPath, preset: FilterPreset.fade, intensity: 0.15);
          if (r2_soft.ok) currentPath = r2_soft.outputPath!;
          break;

        case EnhancePreset.highContrast:
          final r_contrast = await _filters.apply(currentPath, preset: FilterPreset.dramatic, intensity: 0.5);
          if (r_contrast.ok) currentPath = r_contrast.outputPath!;
          break;

        case EnhancePreset.warmCommerce:
          final r_warm = await _relight.relight(currentPath, style: 'warm', intensity: 1.05);
          if (r_warm.ok) currentPath = r_warm.outputPath!;
          break;

        case EnhancePreset.cleanWhite:
          final r_white = await _filters.apply(currentPath, preset: FilterPreset.vivid, intensity: 0.2);
          if (r_white.ok) currentPath = r_white.outputPath!;
          final r2_white = await _relight.relight(currentPath, style: 'studio', intensity: 1.1);
          if (r2_white.ok) currentPath = r2_white.outputPath!;
          break;
      }

      return EditResult(
        ok: true,
        outputPath: currentPath,
        creditsUsed: 2,
        duration: sw.elapsed,
      );
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }
}
