import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/edit_request.dart';
import '../../services/voice_presets_service.dart';
import '../../widgets/app_widgets.dart';

final voicePresetsProvider = StateNotifierProvider<VoicePresetsNotifier, List<VoicePreset>>(
  (_) => VoicePresetsNotifier());

class VoicePresetsNotifier extends StateNotifier<List<VoicePreset>> {
  VoicePresetsNotifier() : super([]) {
    _load();
  }

  final _service = VoicePresetsService();

  void _load() {
    state = _service.getAll();
  }

  Future<void> add(String phrase, EditOp op, {Map<String, dynamic> params = const {}}) async {
    await _service.add(phrase: phrase, operation: op, params: params);
    _load();
  }

  Future<void> remove(String id) async {
    await _service.remove(id);
    _load();
  }

  Future<void> seedDefaults() async {
    await _service.seedDefaults();
    _load();
  }
}

class VoicePresetsScreen extends ConsumerWidget {
  const VoicePresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(voicePresetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: presets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcons.circle(Icons.record_voice_over, size: 88),
                  const SizedBox(height: 16),
                  const Text('No presets yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Save your common voice commands',
                    style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => ref.read(voicePresetsProvider.notifier).seedDefaults(),
                    icon: const Icon(Icons.download),
                    label: const Text('Load Defaults'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: presets.length,
              itemBuilder: (_, i) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: AppIcons.outline(Icons.mic, size: 40),
                  title: Text('"${presets[i].phrase}"'),
                  subtitle: Text(presets[i].operation),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    onPressed: () => ref.read(voicePresetsProvider.notifier).remove(presets[i].id),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final phraseCtrl = TextEditingController();
    EditOp selectedOp = EditOp.removeBg;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('New Voice Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phraseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Voice phrase',
                  hintText: 'remove background',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EditOp>(
                value: selectedOp,
                decoration: const InputDecoration(labelText: 'Operation'),
                items: EditOp.values.map((op) =>
                  DropdownMenuItem(value: op, child: Text(op.name))).toList(),
                onChanged: (v) => setState(() => selectedOp = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (phraseCtrl.text.isNotEmpty) {
                  ref.read(voicePresetsProvider.notifier).add(phraseCtrl.text, selectedOp);
                  Navigator.pop(c);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
