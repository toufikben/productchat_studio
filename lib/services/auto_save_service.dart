import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// AutoSaveService — Saves drafts automatically to prevent data loss.
class AutoSaveService {
  static const _boxName = 'drafts';
  static const _maxDrafts = 10;

  Future<void> saveDraft({
    required String id,
    required String imagePath,
    required Map<String, dynamic> state,
  }) async {
    final box = Hive.box<dynamic>(_boxName);
    final draft = {
      'id': id,
      'imagePath': imagePath,
      'state': jsonEncode(state),
      'ts': DateTime.now().toIso8601String(),
    };

    // Remove existing draft with same id
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final existing = Map<String, dynamic>.from(box.get(key) as Map);
      if (existing['id'] == id) keysToRemove.add(key);
    }
    for (final key in keysToRemove) await box.delete(key);

    await box.add(draft);

    // Trim to max
    if (box.length > _maxDrafts) {
      final sorted = box.keys.toList()
        ..sort((a, b) {
          final ta = Map<String, dynamic>.from(box.get(a) as Map)['ts'] as String;
          final tb = Map<String, dynamic>.from(box.get(b) as Map)['ts'] as String;
          return ta.compareTo(tb);
        });
      final toRemove = sorted.take(box.length - _maxDrafts);
      for (final key in toRemove) await box.delete(key);
    }
  }

  List<DraftEntry> getAll() {
    final box = Hive.box<dynamic>(_boxName);
    final drafts = box.values.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return DraftEntry(
        id: m['id'] as String? ?? '',
        imagePath: m['imagePath'] as String? ?? '',
        state: _decodeState(m['state'] as String? ?? '{}'),
        savedAt: DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return drafts;
  }

  Map<String, dynamic> _decodeState(String value) {
    final decoded = jsonDecode(value);
    return decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
  }

  Future<void> deleteDraft(String id) async {
    final box = Hive.box<dynamic>(_boxName);
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final existing = Map<String, dynamic>.from(box.get(key) as Map);
      if (existing['id'] == id) keysToRemove.add(key);
    }
    for (final key in keysToRemove) await box.delete(key);
  }

  Future<void> clearAll() => Hive.box<dynamic>(_boxName).clear();
}

class DraftEntry {
  final String id;
  final String imagePath;
  final Map<String, dynamic> state;
  final DateTime savedAt;

  const DraftEntry({
    required this.id,
    required this.imagePath,
    required this.state,
    required this.savedAt,
  });
}
