import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// PrivacyService — يحذف كل بيانات المستخدم.
///
/// يشمل:
///   • Hive boxes
///   • Model files
///   • Output images
///   • Input images (المحفوظة)
///   • Cache directory
class PrivacyService {
  /// حذف بيانات محددة.
  Future<DeleteReport> deleteData({
    bool deleteHistory = true,
    bool deleteModels = false,
    bool deleteCachedImages = true,
    bool deleteSettings = false,
    bool deleteAnalytics = true,
  }) async {
    final report = <String, int>{};

    if (deleteHistory) {
      final box = Hive.box('history');
      final paths = _extractPaths(box);
      final deleted = await _deleteFiles(paths);
      await box.clear();
      report['history_entries'] = paths.length;
      report['history_files'] = deleted;
    }

    if (deleteModels) {
      final dir = await getApplicationSupportDirectory();
      final models = Directory('${dir.path}/models');
      if (await models.exists()) {
        final files = models.listSync().length;
        await models.delete(recursive: true);
        report['model_files'] = files;
      }
    }

    if (deleteCachedImages) {
      final tmp = await getTemporaryDirectory();
      if (await tmp.exists()) {
        final files = tmp.listSync().length;
        await tmp.delete(recursive: true);
        await tmp.create(recursive: true);
        report['cached_files'] = files;
      }
    }

    if (deleteSettings) {
      await Hive.box('settings').clear();
      await Hive.box('credits').clear();
      await Hive.box('presets').clear();
      await Hive.box('voice_presets').clear();
      await Hive.box('watermark_presets').clear();
      await Hive.box('export_presets').clear();
      await Hive.box('favorites').clear();
      report['settings_boxes'] = 7;
    }

    if (deleteAnalytics) {
      await Hive.box('analytics').clear();
      await Hive.box('crash_logs').clear();
      report['analytics_boxes'] = 2;
    }

    return DeleteReport(report);
  }

  /// حذف كامل (مع كل شيء).
  Future<DeleteReport> deleteEverything() async {
    return deleteData(
      deleteHistory: true,
      deleteModels: true,
      deleteCachedImages: true,
      deleteSettings: true,
      deleteAnalytics: true,
    );
  }

  /// حجم البيانات المحفوظة.
  Future<StorageUsage> getUsage() async {
    int historyFiles = 0;
    int models = 0;
    int cache = 0;

    // History
    final histBox = Hive.box('history');
    for (final value in histBox.values) {
      if (value is Map) {
        for (final key in ['input', 'output']) {
          final path = value[key]?.toString();
          if (path == null) continue;
          final file = File(path);
          if (await file.exists()) {
            historyFiles += await file.length();
          }
        }
      }
    }

    // Models
    final dir = await getApplicationSupportDirectory();
    final modelsDir = Directory('${dir.path}/models');
    if (await modelsDir.exists()) {
      for (final file in modelsDir.listSync()) {
        if (file is File) {
          models += await file.length();
        }
      }
    }

    // Cache
    final tmp = await getTemporaryDirectory();
    if (await tmp.exists()) {
      for (final file in tmp.listSync()) {
        if (file is File) {
          cache += await file.length();
        }
      }
    }

    return StorageUsage(
      historyBytes: historyFiles,
      modelsBytes: models,
      cacheBytes: cache,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Internal
  // ═══════════════════════════════════════════════════════════════

  List<String> _extractPaths(Box box) {
    final paths = <String>[];
    for (final value in box.values) {
      if (value is Map) {
        for (final key in ['input', 'output']) {
          final path = value[key]?.toString();
          if (path != null && path.isNotEmpty) paths.add(path);
        }
      }
    }
    return paths;
  }

  Future<int> _deleteFiles(List<String> paths) async {
    var count = 0;
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          count++;
        }
      } catch (_) {}
    }
    return count;
  }
}

class DeleteReport {
  final Map<String, int> counts;

  const DeleteReport(this.counts);

  int get totalFiles {
    return counts['history_files']! +
        (counts['model_files'] ?? 0) +
        (counts['cached_files'] ?? 0);
  }

  @override
  String toString() {
    return counts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}

class StorageUsage {
  final int historyBytes;
  final int modelsBytes;
  final int cacheBytes;

  const StorageUsage({
    required this.historyBytes,
    required this.modelsBytes,
    required this.cacheBytes,
  });

  int get totalBytes => historyBytes + modelsBytes + cacheBytes;

  String get historyMb => '${(historyBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  String get modelsMb => '${(modelsBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  String get cacheMb => '${(cacheBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  String get totalMb => '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
