import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('analytics').listenable(),
        builder: (context, Box box, _) {
          final events = box.values
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final byEvent = <String, int>{};
          for (final e in events) {
            final ev = e['event'] as String? ?? 'unknown';
            byEvent[ev] = (byEvent[ev] ?? 0) + 1;
          }

          final sorted = byEvent.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Total events',
                      value: '${events.length}',
                      icon: Icons.bolt,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      label: 'Event types',
                      value: '${byEvent.length}',
                      icon: Icons.category,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (sorted.isNotEmpty) ...[
                const Text('Top events',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...sorted.take(10).map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        title: Text(e.key),
                        trailing: Text('${e.value}'),
                      ),
                    )),
              ] else
                const EmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'No events yet',
                  subtitle: 'Usage statistics will appear here',
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcons.outline(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
}
