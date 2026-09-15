import 'package:flutter/services.dart';

class ModelMetrics {
  final bool ok;
  final int? timeMs;
  final int? memoryMb;
  final int? outputSizeBytes;
  final String? outputPath;
  final String? error;

  const ModelMetrics({
    required this.ok,
    this.timeMs,
    this.memoryMb,
    this.outputSizeBytes,
    this.outputPath,
    this.error,
  });

  factory ModelMetrics.fromMap(Map<dynamic, dynamic> m) => ModelMetrics(
        ok: m['ok'] == true,
        timeMs: (m['timeMs'] as num?)?.toInt(),
        memoryMb: (m['memoryMb'] as num?)?.toInt(),
        outputSizeBytes: (m['outputSizeBytes'] as num?)?.toInt(),
        outputPath: m['outputPath'] as String?,
        error: m['error'] as String?,
      );
}

class ModelComparisonResult {
  final ModelMetrics? migan;
  final ModelMetrics? lama;

  const ModelComparisonResult({this.migan, this.lama});

  String get recommendation {
    if (migan == null) return 'lama';
    if (lama == null) return 'migan';
    if (!migan!.ok) return 'lama';
    if (!lama!.ok) return 'migan';

    // MI-GAN wins if faster OR less memory
    final miganScore = (migan!.timeMs ?? 99999) * 0.5 +
        (migan!.memoryMb ?? 999) * 100;
    final lamaScore = (lama!.timeMs ?? 99999) * 0.5 +
        (lama!.memoryMb ?? 999) * 100;

    return miganScore < lamaScore ? 'migan' : 'lama';
  }
}

class ModelComparisonService {
  static const _channel = MethodChannel('com.productchat/comparison');

  Future<ModelComparisonResult> compare({
    required String imagePath,
    String? miganModelPath,
    String? lamaModelPath,
  }) async {
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'compareModels',
        {
          'path': imagePath,
          if (miganModelPath != null) 'miganModelPath': miganModelPath,
          if (lamaModelPath != null) 'lamaModelPath': lamaModelPath,
        },
      );

      if (raw == null) return const ModelComparisonResult();

      final miganRaw = raw['migan'] as Map?;
      final lamaRaw = raw['lama'] as Map?;

      return ModelComparisonResult(
        migan: miganRaw != null
            ? ModelMetrics.fromMap(miganRaw)
            : null,
        lama: lamaRaw != null
            ? ModelMetrics.fromMap(lamaRaw)
            : null,
      );
    } catch (_) {
      return const ModelComparisonResult();
    }
  }
}
