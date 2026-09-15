import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../services/storage_service.dart';
import '../../services/voice_search_service.dart';
import '../../services/voice_service.dart';
import '../../widgets/app_widgets.dart';

class VoiceSearchScreen extends ConsumerStatefulWidget {
  const VoiceSearchScreen({super.key});
  @override
  ConsumerState<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends ConsumerState<VoiceSearchScreen> {
  final _search = VoiceSearchService();
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _results = StorageService().getHistory();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _results = StorageService().getHistory());
      return;
    }
    final all = StorageService().getHistory();
    setState(() => _results = _search.search(all, query));
  }

  Future<void> _startVoiceSearch() async {
    final voice = ref.read(voiceProvider.notifier);
    await voice.startListening();

    // Listen to first result
    voice.onTranscription.listen((text) {
      if (text.isNotEmpty && mounted) {
        _ctrl.text = text;
        _performSearch(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Search... e.g. "background today"',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _ctrl.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: voice.isListening
                      ? () => ref.read(voiceProvider.notifier).stopListening()
                      : _startVoiceSearch,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: voice.isListening ? AppColors.danger : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      voice.isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (voice.isListening)
            Container(
              padding: const EdgeInsets.all(8),
              child: Text('Listening: "${voice.lastTranscription}"',
                style: const TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No results — try a different search'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final item = _results[i];
                      final output = item['output'] as String?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 48, height: 48,
                              child: output != null && File(output).existsSync()
                                  ? Image.file(File(output), fit: BoxFit.cover)
                                  : Container(color: AppColors.surfaceAlt),
                            ),
                          ),
                          title: Text(item['op'] ?? ''),
                          subtitle: Text(
                            (item['ts'] as String? ?? '').substring(0, 16),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: output != null
                              ? IconButton(
                                  icon: const Icon(Icons.share, size: 18),
                                  onPressed: () => Share.shareXFiles([XFile(output)]),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
