import 'dart:io';
import 'package:image/image.dart' as img;
import '../models/edit_request.dart';

/// CropRotateService — Crop, rotate, flip, and straighten images.
class CropRotateService {
  /// Crop an image to a rectangle.
  Future<EditResult> crop(
    String inputPath, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      final xC = x.clamp(0, src.width - 1).toInt();
      final yC = y.clamp(0, src.height - 1).toInt();
      final wC = width.clamp(1, src.width - xC).toInt();
      final hC = height.clamp(1, src.height - yC).toInt();

      final out = img.copyCrop(src, x: xC, y: yC, width: wC, height: hC);
      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_cropped.png');
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

  /// Rotate by degrees (90, 180, 270 for lossless).
  Future<EditResult> rotate(String inputPath, {required int degrees}) async {
    final sw = Stopwatch()..start();
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      final normalized = ((degrees % 360) + 360) % 360;
      img.Image out;
      switch (normalized) {
        case 90: out = img.copyRotate(src, angle: 90); break;
        case 180: out = img.copyRotate(src, angle: 180); break;
        case 270: out = img.copyRotate(src, angle: 270); break;
        default: out = src;
      }

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_rotated.png');
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

  /// Flip horizontally or vertically.
  Future<EditResult> flip(String inputPath, {required bool horizontal}) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      final out = horizontal ? img.flipHorizontal(src) : img.flipVertical(src);
      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_flipped.png');
      await File(path).writeAsBytes(img.encodePng(out));
      return EditResult(ok: true, outputPath: path, creditsUsed: 1);
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }

  /// Auto-crop to center square.
  Future<EditResult> squareCrop(String inputPath) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      final size = src.width < src.height ? src.width : src.height;
      final x = (src.width - size) ~/ 2;
      final y = (src.height - size) ~/ 2;
      final out = img.copyCrop(src, x: x, y: y, width: size, height: size);

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_square.png');
      await File(path).writeAsBytes(img.encodePng(out));
      return EditResult(ok: true, outputPath: path, creditsUsed: 1);
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }

  /// Resize to specific dimensions.
  Future<EditResult> resize(
    String inputPath, {
    required int width,
    required int height,
    bool maintainAspect = true,
  }) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return const EditResult(ok: false, error: 'Decode failed');

      final out = img.copyResize(
        src,
        width: width,
        height: height,
        maintainAspect: maintainAspect,
        interpolation: img.Interpolation.cubic,
      );

      final path = inputPath.replaceAll(RegExp(r'\.[^.]+$'), '_resized.png');
      await File(path).writeAsBytes(img.encodePng(out));
      return EditResult(ok: true, outputPath: path, creditsUsed: 1);
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }
}
