import 'dart:io';
import 'package:image/image.dart' as img;

/// AI Description Service — يكتب وصف المنتج من الصورة.
/// يستخدم تحليل بصري محلي (بدون API خارجي).
class AIDescriptionService {
  /// توليد وصف المنتج من الصورة.
  Future<ProductDescription> generate(String imagePath, {
    String language = 'ar',
    String tone = 'professional',
    int maxLength = 500,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final im = img.decodeImage(bytes);
      if (im == null) throw Exception('Decode failed');

      // ─── تحليل بصري ───
      final dominantColor = _dominantColor(im);
      final brightness = _brightness(im);
      final contrast = _contrast(im);
      final isSquare = (im.width / im.height - 1.0).abs() < 0.1;

      // ─── توليد الوصف ───
      final colorName = _colorName(dominantColor, language);
      final brightnessLabel = _brightnessLabel(brightness, language);
      final styleLabel = _styleLabel(contrast, language);

      final title = _generateTitle(colorName, styleLabel, language);
      final description = _generateDescription(
        colorName: colorName,
        brightness: brightnessLabel,
        style: styleLabel,
        isSquare: isSquare,
        tone: tone,
        language: language,
        maxLength: maxLength,
      );

      final tags = _generateTags(colorName, styleLabel, language);

      return ProductDescription(
        title: title,
        description: description,
        tags: tags,
        dominantColor: dominantColor,
        style: styleLabel,
      );
    } catch (e) {
      throw Exception('AI Description failed: $e');
    }
  }

  // ─── Helpers ───
  List<int> _dominantColor(img.Image im) {
    var r = 0, g = 0, b = 0, count = 0;
    final step = (im.width * im.height ~/ 1000).clamp(1, 100);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        final p = im.getPixel(x, y);
        r += p.r.toInt();
        g += p.g.toInt();
        b += p.b.toInt();
        count++;
      }
    }
    return [r ~/ count, g ~/ count, b ~/ count];
  }

  double _brightness(img.Image im) {
    var sum = 0.0;
    var count = 0;
    final step = (im.width * im.height ~/ 500).clamp(1, 100);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        final p = im.getPixel(x, y);
        sum += 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        count++;
      }
    }
    return sum / count;
  }

  double _contrast(img.Image im) {
    final values = <double>[];
    final step = (im.width * im.height ~/ 500).clamp(1, 100);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        final p = im.getPixel(x, y);
        values.add(0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      }
    }
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    return variance / 255.0;
  }

  String _colorName(List<int> rgb, String lang) {
    final r = rgb[0], g = rgb[1], b = rgb[2];
    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);
    final sat = max == 0 ? 0 : (max - min) / max;

    if (sat < 0.1) {
      if (max < 60) return lang == 'ar' ? 'أسود' : 'black';
      if (max > 200) return lang == 'ar' ? 'أبيض' : 'white';
      return lang == 'ar' ? 'رمادي' : 'gray';
    }
    if (r > g && r > b) {
      return g > b
          ? (lang == 'ar' ? 'برتقالي' : 'orange')
          : (lang == 'ar' ? 'أحمر' : 'red');
    }
    if (g > r && g > b) {
      return b > r
          ? (lang == 'ar' ? 'سماوي' : 'cyan')
          : (lang == 'ar' ? 'أخضر' : 'green');
    }
    return r > g
        ? (lang == 'ar' ? 'وردي' : 'pink')
        : (lang == 'ar' ? 'أزرق' : 'blue');
  }

  String _brightnessLabel(double b, String lang) {
    if (b < 80) return lang == 'ar' ? 'داكن' : 'dark';
    if (b > 180) return lang == 'ar' ? 'ساطع' : 'bright';
    return lang == 'ar' ? 'متناسق' : 'balanced';
  }

  String _styleLabel(double c, String lang) {
    if (c > 3000) return lang == 'ar' ? 'عالي التباين' : 'high contrast';
    if (c < 500) return lang == 'ar' ? 'ناعم' : 'soft';
    return lang == 'ar' ? 'كلاسيكي' : 'classic';
  }

  String _generateTitle(String color, String style, String lang) {
    return lang == 'ar'
        ? 'منتج $color بأسلوب $style'
        : 'Premium $color product — $style style';
  }

  String _generateDescription({
    required String colorName,
    required String brightness,
    required String style,
    required bool isSquare,
    required String tone,
    required String language,
    required int maxLength,
  }) {
    final isAr = language == 'ar';
    final buffer = StringBuffer();

    if (isAr) {
      buffer.writeln('منتج عالي الجودة بلون $colorName، بإضاءة $brightness وأسلوب $style.');
      if (isSquare) {
        buffer.writeln('الصورة بأبعاد مربعة، مثالية للنشر على منصات التجارة الإلكترونية.');
      }
      buffer.writeln();
      buffer.writeln('المميزات:');
      buffer.writeln('• تصميم عصري وأنيق');
      buffer.writeln('• مواد عالية الجودة');
      buffer.writeln('• مناسب للاستخدام اليومي');
      buffer.writeln('• صورة احترافية جاهزة للنشر');
      buffer.writeln();
      buffer.writeln('مثالي لـ: Amazon، Etsy، Shopify، Instagram');
    } else {
      buffer.writeln('High-quality product in $colorName color, with $brightness lighting and $style style.');
      if (isSquare) {
        buffer.writeln('Square aspect ratio, perfect for e-commerce marketplaces.');
      }
      buffer.writeln();
      buffer.writeln('Features:');
      buffer.writeln('• Modern and elegant design');
      buffer.writeln('• Premium materials');
      buffer.writeln('• Suitable for daily use');
      buffer.writeln('• Professional photo ready to publish');
      buffer.writeln();
      buffer.writeln('Perfect for: Amazon, Etsy, Shopify, Instagram');
    }

    final text = buffer.toString();
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  List<String> _generateTags(String color, String style, String lang) {
    if (lang == 'ar') {
      return ['منتج', color, style, 'احترافي', 'جودة عالية', 'تجارة إلكترونية', 'تسوق'];
    }
    return ['product', color, style, 'professional', 'high quality', 'ecommerce', 'shopping'];
  }
}

class ProductDescription {
  final String title;
  final String description;
  final List<String> tags;
  final List<int> dominantColor;
  final String style;

  const ProductDescription({
    required this.title,
    required this.description,
    required this.tags,
    required this.dominantColor,
    required this.style,
  });
}
