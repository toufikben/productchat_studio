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
    if (path is! String || path.isEmpty || operation is! String || createdAt is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return null;
    return HistoryEntry(path: path, operation: operation, createdAt: parsed);
  }
}

class HistoryService {
  HistoryService({StorageService? storage}) : _storage = storage ?? storageService;

  static const key = 'history.entries.v1';
  static const freeVisibleLimit = 5;
  static const retentionLimit = 100;
  final StorageService _storage;

  List<HistoryEntry> all() {
    final versioned = _storage.getVersionedJson(key);
    final raw = versioned == null ? _storage.getString(key) : null;
    final value = versioned?['entries'] ?? (raw == null ? null : _decode(raw));
    if (value is! List) return const [];
    return value.map(HistoryEntry.fromJson).whereType<HistoryEntry>().toList(growable: false);
  }

  List<HistoryEntry> visible({required bool isPro}) {
    final entries = all();
    return isPro ? entries : entries.take(freeVisibleLimit).toList(growable: false);
  }

  Future<void> record({required String path, required String operation}) async {
    if (path.trim().isEmpty || operation.trim().isEmpty) return;
    final entries = [
      HistoryEntry(path: path, operation: operation, createdAt: DateTime.now()),
      ...all(),
    ].take(retentionLimit).map((entry) => entry.toJson()).toList(growable: false);
    await _storage.setVersionedJson(key, {'entries': entries});
  }

  Future<bool> delete(HistoryEntry entry) async {
    final entries = all();
    final removed = entries.where((item) => item.path != entry.path || item.createdAt != entry.createdAt).toList();
    if (removed.length == entries.length) return false;
    final file = File(entry.path);
    if (_isManagedOutput(entry.path) && await file.exists()) await file.delete();
    await _storage.setVersionedJson(key, {
      'entries': removed.map((item) => item.toJson()).toList(growable: false),
    });
    return true;
  }

  Future<void> clear({bool deleteFiles = true}) async {
    if (deleteFiles) {
      for (final entry in all()) {
        final file = File(entry.path);
        if (_isManagedOutput(entry.path) && await file.exists()) await file.delete();
      }
    }
    await _storage.remove(key);
  }

  static Object? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded;
    } catch (_) {
      return null;
    }
  }

  static bool _isManagedOutput(String path) =>
      path.contains('_free_watermarked.') ||
      path.split(Platform.pathSeparator).last.startsWith('batch_');
}

final historyService = HistoryService();
