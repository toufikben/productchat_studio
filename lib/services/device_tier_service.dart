import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// DeviceTier — مستوى الجهاز لاختيار النموذج المناسب.
enum DeviceTier {
  /// أجهزة قوية (RAM ≥ 8 GB، SoC حديث)
  high,

  /// أجهزة متوسطة (RAM 4-8 GB)
  medium,

  /// أجهزة ضعيفة (RAM < 4 GB)
  low,
}

class DeviceInfoData {
  final DeviceTier tier;
  final int totalRamMb;
  final int availableRamMb;
  final String? socModel;
  final int androidSdk;

  const DeviceInfoData({
    required this.tier,
    required this.totalRamMb,
    required this.availableRamMb,
    this.socModel,
    required this.androidSdk,
  });
}

/// DeviceTierService — يكتشف قدرات الجهاز.
///
/// القرار: اختر MI-GAN لـ high/medium، MODNet لـ low.
class DeviceTierService {
  DeviceInfoData? _cached;

  Future<DeviceInfoData> detect() async {
    if (_cached != null) return _cached!;

    try {
      if (Platform.isAndroid) {
        _cached = await _detectAndroid();
      } else {
        // iOS — نفترض medium (كل الأجهزة iOS 14+ قوية بما يكفي)
        _cached = const DeviceInfoData(
          tier: DeviceTier.medium,
          totalRamMb: 4096,
          availableRamMb: 2048,
          androidSdk: 0,
        );
      }
    } catch (_) {
      _cached = const DeviceInfoData(
        tier: DeviceTier.medium,
        totalRamMb: 4096,
        availableRamMb: 2048,
        androidSdk: 0,
      );
    }

    return _cached!;
  }

  Future<DeviceInfoData> _detectAndroid() async {
    final plugin = DeviceInfoPlugin();
    final info = await plugin.androidInfo;

    // Note: AndroidInfo doesn't directly expose RAM
    // We estimate based on SDK + device characteristics
    final sdk = info.version.sdkInt;
    final manufacturer = info.manufacturer.toLowerCase();
    final model = info.model.toLowerCase();

    // Estimate RAM tier from SDK + manufacturer
    final estimatedRamMb = _estimateRam(sdk, manufacturer, model);
    final tier = _tierFromRam(estimatedRamMb);

    return DeviceInfoData(
      tier: tier,
      totalRamMb: estimatedRamMb,
      availableRamMb: estimatedRamMb ~/ 2,
      socModel: info.board,
      androidSdk: sdk,
    );
  }

  int _estimateRam(int sdk, String manufacturer, String model) {
    // High-end indicators
    if (manufacturer.contains('samsung') &&
        (model.contains('s2') ||
            model.contains('s23') ||
            model.contains('s24'))) {
      return 12288;
    }
    if (manufacturer.contains('google') &&
        (model.contains('pixel 7') ||
            model.contains('pixel 8') ||
            model.contains('pixel 9'))) {
      return 12288;
    }
    if (manufacturer.contains('oneplus') && model.contains('1')) {
      return 12288;
    }

    // SDK-based fallback
    if (sdk >= 33) return 8192;
    if (sdk >= 30) return 6144;
    if (sdk >= 28) return 4096;
    return 2048;
  }

  DeviceTier _tierFromRam(int ramMb) {
    if (ramMb >= 8000) return DeviceTier.high;
    if (ramMb >= 4000) return DeviceTier.medium;
    return DeviceTier.low;
  }

  /// التوصية: أي نموذج إزالة خلفية يناسب هذا الجهاز؟
  String recommendedBackgroundModel() {
    final tier = _cached?.tier ?? DeviceTier.medium;
    switch (tier) {
      case DeviceTier.high:
        return 'migan'; // جودة أعلى
      case DeviceTier.medium:
        return 'migan'; // متوازن
      case DeviceTier.low:
        return 'modnet'; // أخف
    }
  }

  /// هل نحتاج تقليل جودة الصورة قبل المعالجة؟
  bool shouldReduceQuality() {
    final tier = _cached?.tier ?? DeviceTier.medium;
    return tier == DeviceTier.low;
  }
}

final deviceTierProvider = Provider<DeviceTierService>(
  (_) => DeviceTierService(),
);
