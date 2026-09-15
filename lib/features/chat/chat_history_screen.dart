import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_widgets.dart';

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = StorageService();
    final items = store.getHistory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showConfirmDialog(context,
                  title: 'Clear history?',
                  message: 'Cannot be undone',
                  destructive: true);
                if (ok) {
                  await store.clearHistory();
                  (context as Element).markNeedsBuild();
                }
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No history yet',
              subtitle: 'Your edits will appear here',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _HistoryCard(item: items[i]),
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final output = item['output'] as String?;
    final input = item['input'] as String?;
    final op = item['op'] as String? ?? 'unknown';
    final ts = item['ts'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60, height: 60,
              child: output != null && File(output).existsSync()
                  ? Image.file(File(output), fit: BoxFit.cover)
                  : Container(color: AppColors.surfaceAlt,
                      child: const Icon(Icons.image, color: AppColors.textTertiary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_labelFor(op), style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_formatDate(ts),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ],
          )),
          if (output != null && File(output).existsSync())
            IconButton(
              icon: const Icon(Icons.share, size: 20),
              onPressed: () => Share.shareXFiles([XFile(output)]),
            ),
        ],
      ),
    );
  }

  String _labelFor(String op) => switch (op) {
    'removeBg' => 'Background Removed',
    'enhance' => 'Enhanced',
    'shadow' => 'Shadow Added',
    'relight' => 'Relit',
    'colorize' => 'Colorized',
    'inpaint' => 'Object Removed',
    'conversational' => 'AI Edit',
    _ => op,
  };

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
