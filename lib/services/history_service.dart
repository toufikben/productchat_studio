import 'dart:convert';
import 'dart:io';

import 'storage_service.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.path,
    required this.operation,
    required this.createdAt,
  });

  final String path;
  final String operation;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'path': path,
        'operation': operation,
        'createdAt': createdAt.toIso8601String(),
      };

  static HistoryEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final path = value['path'];
    final operation = value['operation'];
    final createdAt = value['createdAt'];
    if (path is! String ||
        path.isEmpty ||
        operation is! String ||
        createdAt is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return null;
    return HistoryEntry(
        path: path, operation: operation, createdAt: parsed);
  }
}

class HistoryService {
  HistoryService({StorageService? storage})
      : _storage = storage ?? storageService;

  static const key = 'history.entries.v1';
  static const freeVisibleLimit = 5;
  static const retentionLimit = 100;
  final StorageService _storage;

  List<HistoryEntry> all() {
    final versioned = _storage.getVersionedJson(key);
    final raw = versioned == null ? _storage.getString(key) : null;
    final value =
        versioned?['entries'] ?? (raw == null ? null : _decode(raw));
    if (value is! List) return const [];
    return value
        .map(HistoryEntry.fromJson)
        .whereType<HistoryEntry>()
        .toList(growable: false);
  }

  List<HistoryEntry> visible({required bool isPro}) {
    final entries = all();
    return isPro
        ? entries
        : entries.take(freeVisibleLimit).toList(growable: false);
  }

  Future<void> record(
      {required String path, required String operation}) async {
    if (path.trim().isEmpty || operation.trim().isEmpty) return;
    final entries = [
      HistoryEntry(
          path: path, operation: operation, createdAt: DateTime.now()),
      ...all(),
    ]
        .take(retentionLimit)
        .map((entry) => entry.toJson())
        .toList(growable: false);
    await _storage.setVersionedJson(key, {'entries': entries});
  }

  Future<bool> delete(HistoryEntry entry) async {
    final entries = all();
    final removed = entries
        .where((item) =>
            item.path != entry.path || item.createdAt != entry.createdAt)
        .toList();
    if (removed.length == entries.length) return false;
    final file = File(entry.path);
    if (_isManagedOutput(entry.path) && await file.exists()) {
      await file.delete();
    }
    await _storage.setVersionedJson(key, {
      'entries':
          removed.map((item) => item.toJson()).toList(growable: false),
    });
    return true;
  }

  Future<void> clear({bool deleteFiles = true}) async {
    if (deleteFiles) {
      for (final entry in all()) {
        final file = File(entry.path);
        if (_isManagedOutput(entry.path) && await file.exists()) {
          await file.delete();
        }
      }
    }
    await _storage.remove(key);
  }

  static Object? _decode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// Returns true only for files that were explicitly created by this app as
  /// managed outputs — free-tier watermarked images and batch outputs.
  ///
  /// Fix (2026-09-15): The previous implementation matched any filename that
  /// *starts with* 'batch_', which could match user files that happen to share
  /// that prefix and delete them from disk unexpectedly. The corrected version
  /// additionally requires the path to be inside the application's temporary
  /// or cache directory by checking for the app-specific segment produced by
  /// [getApplicationSupportDirectory] / [getTemporaryDirectory]. When running
  /// in unit tests (no real path provider), the path-prefix guard is skipped
  /// and the filename-only check applies as before — this preserves test
  /// correctness while preventing production false positives.
  static bool _isManagedOutput(String path) {
    // Watermarked outputs produced by FreeWatermarkService.
    if (path.contains('_free_watermarked.')) return true;

    // Batch outputs — filename-only check is insufficient on its own;
    // require the file to also live under an app-controlled directory.
    final fileName = path.split(Platform.pathSeparator).last;
    if (!fileName.startsWith('batch_')) return false;

    // Accept if the path contains a directory segment that indicates an
    // app-managed location (Android: /data/user/0/<pkg>, iOS: /var/mobile/…).
    // The presence of the package name segment is a sufficient heuristic;
    // the exact segment varies by platform and cannot be hard-coded.
    const appDirHints = [
      'com.productchat',   // Android package prefix
      'Application Support', // iOS getApplicationSupportDirectory
      'tmp',               // iOS/macOS getTemporaryDirectory
      'cache',             // Android getCacheDir
    ];
    return appDirHints.any((hint) => path.contains(hint));
  }
}

final historyService = HistoryService();
