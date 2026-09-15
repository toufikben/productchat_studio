import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class EditorPreset {
  final String id;
  final String name;
  final Map<String, dynamic> operations;
  final DateTime createdAt;

  EditorPreset({
    required this.id,
    required this.name,
    required this.operations,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'operations': operations,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EditorPreset.fromMap(Map m) => EditorPreset(
    id: m['id'],
    name: m['name'],
    operations: Map<String, dynamic>.from(m['operations']),
    createdAt: DateTime.parse(m['createdAt']),
  );
}

final presetsProvider = StateNotifierProvider<PresetsNotifier, List<EditorPreset>>(
  (_) => PresetsNotifier());

class PresetsNotifier extends StateNotifier<List<EditorPreset>> {
  PresetsNotifier() : super([]) { _load(); }

  void _load() {
    final box = Hive.box('presets');
    state = box.values.map((e) => EditorPreset.fromMap(Map.from(e))).toList();
  }

  Future<void> add(String name, Map<String, dynamic> operations) async {
    final preset = EditorPreset(
      id: const Uuid().v4(),
      name: name,
      operations: operations,
      createdAt: DateTime.now(),
    );
    await Hive.box('presets').add(preset.toMap());
    _load();
  }

  Future<void> remove(String id) async {
    final box = Hive.box('presets');
    final keys = box.keys.where((k) {
      final m = Map.from(box.get(k));
      return m['id'] == id;
    }).toList();
    for (final k in keys) await box.delete(k);
    _load();
  }
}

class PresetsScreen extends ConsumerStatefulWidget {
  const PresetsScreen({super.key});
  @override
  ConsumerState<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends ConsumerState<PresetsScreen> {
  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: presets.isEmpty
          ? const EmptyState(
              icon: Icons.tune,
              title: 'No presets yet',
              subtitle: 'Save your favorite combinations of operations',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: presets.length,
              itemBuilder: (_, i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: AppIcons.outline(Icons.tune, size: 40),
                  title: Text(presets[i].name),
                  subtitle: Text('${presets[i].operations.length} operations'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    onPressed: () => ref.read(presetsProvider.notifier).remove(presets[i].id),
                  ),
                  onTap: () => Navigator.pop(context, presets[i]),
                ),
              ),
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New Preset'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Preset name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(presetsProvider.notifier).add(name, {'sample': true});
      if (context.mounted) showSuccessSnack(context, 'Preset saved');
    }
  }
}
