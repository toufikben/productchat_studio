import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class ExportPreset {
  final String id;
  final String name;
  final String format;
  final int size;
  final int quality;
  final bool addWatermark;
  final String? watermarkPresetId;

  const ExportPreset({
    required this.id,
    required this.name,
    required this.format,
    required this.size,
    required this.quality,
    this.addWatermark = false,
    this.watermarkPresetId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'format': format,
    'size': size,
    'quality': quality,
    'addWatermark': addWatermark,
    'watermarkPresetId': watermarkPresetId,
  };

  factory ExportPreset.fromMap(Map<String, dynamic> m) => ExportPreset(
    id: m['id'] as String? ?? '',
    name: m['name'] as String? ?? '',
    format: m['format'] as String? ?? 'jpg',
    size: m['size'] as int? ?? 2048,
    quality: m['quality'] as int? ?? 92,
    addWatermark: m['addWatermark'] as bool? ?? false,
    watermarkPresetId: m['watermarkPresetId'] as String?,
  );

  /// Pre-built platform presets.
  static List<ExportPreset> defaults() => [
    const ExportPreset(
      id: 'amazon_main',
      name: 'Amazon Main',
      format: 'jpg',
      size: 2000,
      quality: 95,
    ),
    const ExportPreset(
      id: 'etsy_listing',
      name: 'Etsy Listing',
      format: 'jpg',
      size: 2400,
      quality: 92,
    ),
    const ExportPreset(
      id: 'shopify_product',
      name: 'Shopify Product',
      format: 'jpg',
      size: 2048,
      quality: 90,
    ),
    const ExportPreset(
      id: 'instagram_post',
      name: 'Instagram Post',
      format: 'jpg',
      size: 1080,
      quality: 88,
    ),
    const ExportPreset(
      id: 'web_optimized',
      name: 'Web Optimized',
      format: 'webp',
      size: 1200,
      quality: 80,
    ),
    const ExportPreset(
      id: 'print_ready',
      name: 'Print Ready',
      format: 'png',
      size: 3000,
      quality: 100,
    ),
  ];
}

class ExportPresetService {
  static const _boxName = 'export_presets';

  List<ExportPreset> getAll() {
    final custom = Hive.box<dynamic>(_boxName)
        .values
        .map((e) => ExportPreset.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return [...ExportPreset.defaults(), ...custom];
  }

  List<ExportPreset> getCustom() {
    return Hive.box<dynamic>(_boxName)
        .values
        .map((e) => ExportPreset.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ExportPreset> add({
    required String name,
    required String format,
    required int size,
    required int quality,
    bool addWatermark = false,
    String? watermarkPresetId,
  }) async {
    final preset = ExportPreset(
      id: const Uuid().v4(),
      name: name,
      format: format,
      size: size,
      quality: quality,
      addWatermark: addWatermark,
      watermarkPresetId: watermarkPresetId,
    );
    await Hive.box<dynamic>(_boxName).add(preset.toMap());
    return preset;
  }

  Future<void> remove(String id) async {
    final box = Hive.box<dynamic>(_boxName);
    final keys = box.keys.where((k) {
      final p = ExportPreset.fromMap(Map<String, dynamic>.from(box.get(k) as Map));
      return p.id == id;
    }).toList();
    for (final k in keys) await box.delete(k);
  }
}
