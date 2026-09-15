import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_widgets.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});
  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final all = StorageService().getHistory();
    final items = _filter == 'all'
        ? all
        : all.where((i) => i['op'] == _filter).toList();

    // Group by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final ts = item['ts'] as String? ?? '';
      final date = ts.isNotEmpty ? ts.substring(0, 10) : 'Unknown';
      grouped.putIfAbsent(date, () => []).add(item);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'removeBg', child: Text('Remove BG')),
              const PopupMenuItem(value: 'enhance', child: Text('Enhance')),
              const PopupMenuItem(value: 'shadow', child: Text('Shadow')),
              const PopupMenuItem(value: 'relight', child: Text('Relight')),
              const PopupMenuItem(value: 'colorize', child: Text('Colorize')),
            ],
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.timeline,
              title: 'No activity yet',
              subtitle: 'Your edits will appear here in chronological order',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (_, dateIndex) {
                final date = sortedDates[dateIndex];
                final dateItems = grouped[date]!;
                return _DateGroup(date: date, items: dateItems);
              },
            ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> items;
  const _DateGroup({required this.date, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(date),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(child: Divider(color: AppColors.border)),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _TimelineItem(item: item)),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Yesterday';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TimelineItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final output = item['output'] as String?;
    final op = item['op'] as String? ?? '';
    final ts = item['ts'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: output != null && File(output).existsSync()
                  ? Image.file(File(output), fit: BoxFit.cover)
                  : Container(
                      color: AppColors.surfaceAlt,
                      child: Icon(_iconFor(op),
                          color: AppColors.textTertiary, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelFor(op),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  ts.length > 11 ? ts.substring(11, 16) : '',
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (output != null && File(output).existsSync())
            IconButton(
              icon: const Icon(Icons.share, size: 18),
              onPressed: () => Share.shareXFiles([XFile(output)]),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String op) => switch (op) {
    'removeBg' => Icons.content_cut,
    'enhance' => Icons.high_quality,
    'shadow' => Icons.brightness_4,
    'relight' => Icons.light_mode,
    'colorize' => Icons.color_lens,
    'inpaint' => Icons.healing,
    _ => Icons.image,
  };

  String _labelFor(String op) => switch (op) {
    'removeBg' => 'Background Removed',
    'enhance' => 'Enhanced',
    'shadow' => 'Shadow Added',
    'relight' => 'Lighting Adjusted',
    'colorize' => 'Colorized',
    'inpaint' => 'Object Removed',
    _ => op,
  };
}
