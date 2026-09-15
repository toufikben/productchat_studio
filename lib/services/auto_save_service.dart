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
    final box = Hive.box(_boxName);
    final draft = {
      'id': id,
      'imagePath': imagePath,
      'state': jsonEncode(state),
      'ts': DateTime.now().toIso8601String(),
    };

    // Remove existing draft with same id
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final existing = Map<String, dynamic>.from(box.get(key));
      if (existing['id'] == id) keysToRemove.add(key);
    }
    for (final key in keysToRemove) await box.delete(key);

    await box.add(draft);

    // Trim to max
    if (box.length > _maxDrafts) {
      final sorted = box.keys.toList()
        ..sort((a, b) {
          final ta = Map.from(box.get(a))['ts'] as String;
          final tb = Map.from(box.get(b))['ts'] as String;
          return ta.compareTo(tb);
        });
      final toRemove = sorted.take(box.length - _maxDrafts);
      for (final key in toRemove) await box.delete(key);
    }
  }

  List<DraftEntry> getAll() {
    final box = Hive.box(_boxName);
    final drafts = box.values.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return DraftEntry(
        id: m['id'] ?? '',
        imagePath: m['imagePath'] ?? '',
        state: Map<String, dynamic>.from(
          jsonDecode(m['state'] as String? ?? '{}'),
        ),
        savedAt: DateTime.tryParse(m['ts'] ?? '') ?? DateTime.now(),
      );
    }).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return drafts;
  }

  Future<void> deleteDraft(String id) async {
    final box = Hive.box(_boxName);
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final existing = Map<String, dynamic>.from(box.get(key));
      if (existing['id'] == id) keysToRemove.add(key);
    }
    for (final key in keysToRemove) await box.delete(key);
  }

  Future<void> clearAll() => Hive.box(_boxName).clear();
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
