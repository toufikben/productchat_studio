import 'dart:io';
import 'package:image/image.dart' as img;

/// WatermarkService — Adds a configurable watermark to exported images.
class WatermarkService {
  /// يضيف علامة مائية نصية إلى الصورة.
  /// [position]: bottomRight, bottomLeft, topRight, topLeft, center
  Future<String> apply(
    String imagePath, {
    String text = 'ProductChat Studio',
    String position = 'bottomRight',
    double opacity = 0.6,
    double scale = 0.15,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return imagePath;

    // Simple text rendering using pixel drawing
    // (Since image package doesn't have text rendering built-in for arbitrary fonts)
    // We draw a semi-transparent band with text indicator

    final bandHeight = (image.height * 0.06).toInt();
    final bandY = switch (position) {
      'bottomLeft' || 'bottomRight' => image.height - bandHeight,
      'topLeft' || 'topRight' => 0,
      _ => (image.height - bandHeight) ~/ 2,
    };

    for (var y = bandY; y < bandY + bandHeight && y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final p = image.getPixel(x, y);
        final newR = (p.r * (1 - opacity * 0.5)).round();
        final newG = (p.g * (1 - opacity * 0.5)).round();
        final newB = (p.b * (1 - opacity * 0.5)).round();
        image.setPixelRgb(x, y, newR, newG, newB);
      }
    }

    final path = imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_wm.png');
    await File(path).writeAsBytes(img.encodePng(image));
    return path;
  }

  /// يضيف شعاراً كعلامة مائية.
  Future<String> applyLogo(
    String imagePath,
    String logoPath, {
    String position = 'bottomRight',
    double scale = 0.12,
    double opacity = 0.85,
  }) async {
    final imgBytes = await File(imagePath).readAsBytes();
    final logoBytes = await File(logoPath).readAsBytes();
    final image = img.decodeImage(imgBytes);
    final logo = img.decodeImage(logoBytes);
    if (image == null || logo == null) return imagePath;

    final logoW = (image.width * scale).toInt();
    final logoH = (logo.height * logoW / logo.width).toInt();
    final resized = img.copyResize(logo, width: logoW, height: logoH);

    final (x, y) = switch (position) {
      'bottomLeft' => (24, image.height - logoH - 24),
      'topRight' => (image.width - logoW - 24, 24),
      'topLeft' => (24, 24),
      'center' => ((image.width - logoW) ~/ 2, (image.height - logoH) ~/ 2),
      _ => (image.width - logoW - 24, image.height - logoH - 24),
    };

    img.compositeImage(image, resized, dstX: x, dstY: y);

    final path = imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_logo.png');
    await File(path).writeAsBytes(img.encodePng(image));
    return path;
  }
}
