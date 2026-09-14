import 'dart:convert';

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
  final StorageService _storage;

  List<HistoryEntry> all() {
    final raw = _storage.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(HistoryEntry.fromJson)
          .whereType<HistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  List<HistoryEntry> visible({required bool isPro}) {
    final entries = all();
    return isPro
        ? entries
        : entries.take(freeVisibleLimit).toList(growable: false);
  }

  Future<void> record({required String path, required String operation}) async {
    if (path.trim().isEmpty || operation.trim().isEmpty) return;
    final entries = [
      HistoryEntry(path: path, operation: operation, createdAt: DateTime.now()),
      ...all(),
    ];
    await _storage.set(
      key,
      jsonEncode(entries.take(100).map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> clear() => _storage.remove(key);
}

final historyService = HistoryService();
