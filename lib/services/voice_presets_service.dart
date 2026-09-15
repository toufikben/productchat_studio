import 'package:uuid/uuid.dart';
import '../models/edit_request.dart';

/// VoicePreset — أمر صوتي محفوظ.
class VoicePreset {
  final String id;
  final String phrase;
  final String operation;
  final Map<String, dynamic> params;
  final DateTime createdAt;

  const VoicePreset({
    required this.id,
    required this.phrase,
    required this.operation,
    this.params = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'phrase': phrase,
    'operation': operation,
    'params': params,
    'createdAt': createdAt.toIso8601String(),
  };

  factory VoicePreset.fromMap(Map m) => VoicePreset(
    id: m['id'],
    phrase: m['phrase'],
    operation: m['operation'],
    params: Map<String, dynamic>.from(m['params'] ?? {}),
    createdAt: DateTime.parse(m['createdAt']),
  );
}

/// VoicePresetsService — يدير الأوامر الصوتية المحفوظة.
class VoicePresetsService {
  static const _boxName = 'voice_presets';

  List<VoicePreset> getAll() {
    final box = Hive.box(_boxName);
    return box.values.map((e) => VoicePreset.fromMap(Map.from(e))).toList();
  }

  Future<VoicePreset> add({
    required String phrase,
    required EditOp operation,
    Map<String, dynamic> params = const {},
  }) async {
    final preset = VoicePreset(
      id: const Uuid().v4(),
      phrase: phrase,
      operation: operation.name,
      params: params,
      createdAt: DateTime.now(),
    );
    await Hive.box(_boxName).add(preset.toMap());
    return preset;
  }

  Future<void> remove(String id) async {
    final box = Hive.box(_boxName);
    final keys = box.keys.where((k) {
      final m = Map.from(box.get(k));
      return m['id'] == id;
    }).toList();
    for (final k in keys) await box.delete(k);
  }

  Future<void> clear() => Hive.box(_boxName).clear();

  /// يطابق نص صوتي مع presets مخزنة.
  VoicePreset? match(String query) {
    final q = query.toLowerCase().trim();
    final presets = getAll();

    // Exact phrase match
    for (final p in presets) {
      if (p.phrase.toLowerCase() == q) return p;
    }

    // Partial match
    for (final p in presets) {
      if (q.contains(p.phrase.toLowerCase()) ||
          p.phrase.toLowerCase().contains(q)) {
        return p;
      }
    }
    return null;
  }

  /// Presets افتراضية جاهزة.
  Future<void> seedDefaults() async {
    if (getAll().isNotEmpty) return;
    await add(phrase: 'remove background', operation: EditOp.removeBg);
    await add(phrase: 'enhance image', operation: EditOp.enhance);
    await add(phrase: 'add shadow', operation: EditOp.shadow);
    await add(phrase: 'make it warm', operation: EditOp.relight, params: {'style': 'warm'});
    await add(phrase: 'make it cool', operation: EditOp.relight, params: {'style': 'cool'});
    await add(phrase: 'colorize', operation: EditOp.colorize);
  }
}
