import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

/// WatermarkPreset — Configurable watermark for exports.
class WatermarkPreset {
  final String id;
  final String name;
  final String type; // 'text' or 'logo'
  final String? text;
  final String? logoPath;
  final String position; // topLeft, topRight, bottomLeft, bottomRight, center
  final double scale;
  final double opacity;
  final String fontFamily;
  final int fontSize;
  final String color; // hex

  const WatermarkPreset({
    required this.id,
    required this.name,
    required this.type,
    this.text,
    this.logoPath,
    this.position = 'bottomRight',
    this.scale = 0.15,
    this.opacity = 0.85,
    this.fontFamily = 'Inter',
    this.fontSize = 24,
    this.color = '#FFFFFF',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'text': text,
    'logoPath': logoPath,
    'position': position,
    'scale': scale,
    'opacity': opacity,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'color': color,
  };

  factory WatermarkPreset.fromMap(Map<String, dynamic> m) => WatermarkPreset(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    type: m['type'] as String? ?? 'text',
    text: m['text'] as String?,
    logoPath: m['logoPath'] as String?,
    position: m['position'] as String? ?? 'bottomRight',
    scale: (m['scale'] as num?)?.toDouble() ?? 0.15,
    opacity: (m['opacity'] as num?)?.toDouble() ?? 0.85,
    fontFamily: m['fontFamily'] as String? ?? 'Inter',
    fontSize: m['fontSize'] as int? ?? 24,
    color: m['color'] as String? ?? '#FFFFFF',
  );

  WatermarkPreset copyWith({
    String? name,
    String? type,
    String? text,
    String? logoPath,
    String? position,
    double? scale,
    double? opacity,
    String? fontFamily,
    int? fontSize,
    String? color,
  }) =>
      WatermarkPreset(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        text: text ?? this.text,
        logoPath: logoPath ?? this.logoPath,
        position: position ?? this.position,
        scale: scale ?? this.scale,
        opacity: opacity ?? this.opacity,
        fontFamily: fontFamily ?? this.fontFamily,
        fontSize: fontSize ?? this.fontSize,
        color: color ?? this.color,
      );
}

/// WatermarkPresetService — Manage multiple watermark presets.
class WatermarkPresetService {
  static const _boxName = 'watermark_presets';

  List<WatermarkPreset> getAll() {
    return Hive.box<dynamic>(_boxName).values
        .map((e) => WatermarkPreset.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<WatermarkPreset> add(WatermarkPreset preset) async {
    final withId = WatermarkPreset(
      id: const Uuid().v4(),
      name: preset.name,
      type: preset.type,
      text: preset.text,
      logoPath: preset.logoPath,
      position: preset.position,
      scale: preset.scale,
      opacity: preset.opacity,
      fontFamily: preset.fontFamily,
      fontSize: preset.fontSize,
      color: preset.color,
    );
    await Hive.box<dynamic>(_boxName).add(withId.toMap());
    return withId;
  }

  Future<void> update(WatermarkPreset preset) async {
    final box = Hive.box<dynamic>(_boxName);
    for (final key in box.keys) {
      final existing = WatermarkPreset.fromMap(Map<String, dynamic>.from(box.get(key) as Map));
      if (existing.id == preset.id) {
        await box.put(key, preset.toMap());
        return;
      }
    }
  }

  Future<void> remove(String id) async {
    final box = Hive.box<dynamic>(_boxName);
    final keys = box.keys.where((k) {
      final m = WatermarkPreset.fromMap(Map<String, dynamic>.from(box.get(k) as Map));
      return m.id == id;
    }).toList();
    for (final k in keys) await box.delete(k);
  }

  /// Apply watermark to image.
  Future<String> apply(String imagePath, WatermarkPreset preset) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return imagePath;

    if (preset.type == 'logo' && preset.logoPath != null) {
      final logoBytes = await File(preset.logoPath!).readAsBytes();
      final logo = img.decodeImage(logoBytes);
      if (logo != null) {
        final logoW = (image.width * preset.scale).toInt();
        final logoH = (logo.height * logoW / logo.width).toInt();
        final resized = img.copyResize(logo, width: logoW, height: logoH);
        final (x, y) = _position(image.width, image.height, logoW, logoH, preset.position);
        img.compositeImage(image, resized, dstX: x, dstY: y);
      }
    } else if (preset.type == 'text' && preset.text != null) {
      // Simple text band with opacity
      final bandHeight = preset.fontSize + 16;
      final (x, y) = _position(image.width, image.height,
          preset.text!.length * preset.fontSize ~/ 2, bandHeight, preset.position);

      for (var dy = 0; dy < bandHeight; dy++) {
        for (var dx = 0; dx < preset.text!.length * preset.fontSize ~/ 2; dx++) {
          final px = x + dx;
          final py = y + dy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            final p = image.getPixel(px, py);
            final alpha = preset.opacity;
            image.setPixelRgb(
              px, py,
              (p.r * (1 - alpha * 0.5)).round(),
              (p.g * (1 - alpha * 0.5)).round(),
              (p.b * (1 - alpha * 0.5)).round(),
            );
          }
        }
      }
    }

    final path = imagePath.replaceAll(RegExp(r'\.[^.]+$'), '_wm.png');
    await File(path).writeAsBytes(img.encodePng(image));
    return path;
  }

  (int, int) _position(int w, int h, int wmW, int wmH, String pos) {
    switch (pos) {
      case 'topLeft': return (16, 16);
      case 'topRight': return (w - wmW - 16, 16);
      case 'bottomLeft': return (16, h - wmH - 16);
      case 'center': return ((w - wmW) ~/ 2, (h - wmH) ~/ 2);
      default: return (w - wmW - 16, h - wmH - 16);
    }
  }
}
