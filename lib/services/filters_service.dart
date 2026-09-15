import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import '../models/edit_request.dart';

enum FilterPreset {
  none,
  vivid,
  vintage,
  mono,
  sepia,
  cool,
  warm,
  dramatic,
  fade,
  blackWhite,
  film,
  cinematic,
  matte,
  sunny,
  cold,
}

class FiltersService {
  Future<EditResult> apply(
    String inputPath, {
    required FilterPreset preset,
    double intensity = 1.0,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      final out = _applyPreset(src, preset, intensity);
      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_${preset.name}.png');
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

  img.Image _applyPreset(img.Image src, FilterPreset preset, double intensity) {
    final out = img.Image(width: src.width, height: src.height, numChannels: 3);

    for (var y = 0; y < src.height; y++) {
      for (var x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        var r = p.r.toDouble();
        var g = p.g.toDouble();
        var b = p.b.toDouble();

        switch (preset) {
          case FilterPreset.vivid:
            r = ((r - 128) * 1.4 + 128).clamp(0, 255);
            g = ((g - 128) * 1.4 + 128).clamp(0, 255);
            b = ((b - 128) * 1.4 + 128).clamp(0, 255);
            break;
          case FilterPreset.vintage:
            r = r * 1.1 + 15;
            g = g * 0.95 + 10;
            b = b * 0.85;
            break;
          case FilterPreset.mono:
            final lum = 0.299 * r + 0.587 * g + 0.114 * b;
            r = g = b = lum;
            break;
          case FilterPreset.sepia:
            final sr = r * 0.393 + g * 0.769 + b * 0.189;
            final sg = r * 0.349 + g * 0.686 + b * 0.168;
            final sb = r * 0.272 + g * 0.534 + b * 0.131;
            r = sr; g = sg; b = sb;
            break;
          case FilterPreset.cool:
            r *= 0.9; g *= 1.0; b *= 1.15;
            break;
          case FilterPreset.warm:
            r *= 1.15; g *= 1.02; b *= 0.9;
            break;
          case FilterPreset.dramatic:
            r = ((r - 128) * 1.5 + 128).clamp(0, 255);
            g = ((g - 128) * 1.5 + 128).clamp(0, 255);
            b = ((b - 128) * 1.5 + 128).clamp(0, 255);
            break;
          case FilterPreset.fade:
            r = r * 0.7 + 50;
            g = g * 0.7 + 50;
            b = b * 0.7 + 50;
            break;
          case FilterPreset.blackWhite:
            final lum = (0.299 * r + 0.587 * g + 0.114 * b);
            r = g = b = lum > 128 ? 255 : 0;
            break;
          case FilterPreset.film:
            r = r * 1.05 + 5;
            g = g * 1.0;
            b = b * 0.95 + 5;
            break;
          case FilterPreset.cinematic:
            r = r * 1.1;
            g = g * 1.0;
            b = b * 0.9;
            final avg = (r + g + b) / 3;
            r = ((r - avg) * 1.3 + avg).clamp(0, 255);
            g = ((g - avg) * 1.3 + avg).clamp(0, 255);
            b = ((b - avg) * 1.3 + avg).clamp(0, 255);
            break;
          case FilterPreset.matte:
            r = r * 0.85 + 20;
            g = g * 0.85 + 20;
            b = b * 0.85 + 20;
            break;
          case FilterPreset.sunny:
            r *= 1.1; g *= 1.05; b *= 0.95;
            break;
          case FilterPreset.cold:
            r *= 0.85; g *= 1.0; b *= 1.2;
            break;
          case FilterPreset.none:
            break;
        }

        // Blend with intensity
        final nr = (p.r + (r - p.r) * intensity).clamp(0, 255).toInt();
        final ng = (p.g + (g - p.g) * intensity).clamp(0, 255).toInt();
        final nb = (p.b + (b - p.b) * intensity).clamp(0, 255).toInt();
        out.setPixelRgb(x, y, nr, ng, nb);
      }
    }
    return out;
  }
}
