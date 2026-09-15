import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../services/crash_reporting_service.dart';
import '../../widgets/app_widgets.dart';

class CrashLogsScreen extends StatefulWidget {
  const CrashLogsScreen({super.key});
  @override
  State<CrashLogsScreen> createState() => _CrashLogsScreenState();
}

class _CrashLogsScreenState extends State<CrashLogsScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = CrashReportingService.getAll();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crash Logs'),
        actions: [
          if (logs.isNotEmpty) ...[
            IconButton(icon: const Icon(Icons.copy_all), tooltip: 'Copy JSON', onPressed: () {
              Clipboard.setData(ClipboardData(text: CrashReportingService.exportAsJson()));
              showSuccessSnack(context, 'Copied to clipboard');
            }),
            IconButton(icon: const Icon(Icons.delete_sweep), tooltip: 'Clear all', onPressed: () async {
              final ok = await showConfirmDialog(context, title: 'Clear crash logs?', message: 'All crash reports will be deleted.', destructive: true);
              if (ok) { await CrashReportingService.clear(); if (mounted) setState(() {}); }
            }),
          ],
        ],
      ),
      body: logs.isEmpty
          ? const EmptyState(icon: Icons.check_circle_outline, title: 'No crashes', subtitle: 'Great! The app has been running smoothly')
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: logs.length, itemBuilder: (_, i) => _CrashCard(log: logs[i])),
    );
  }
}

class _CrashCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _CrashCard({required this.log});
  @override
  Widget build(BuildContext context) {
    final type = log['type'] as String? ?? 'unknown';
    final error = log['error'] as String? ?? '';
    final stack = log['stack'] as String? ?? '';
    final ts = log['ts'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)), child: Text(type.toUpperCase(), style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.w700))), const Spacer(), Text(ts.length > 16 ? ts.substring(0, 16) : ts, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10))]),
        const SizedBox(height: 8), Text(error, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), maxLines: 4, overflow: TextOverflow.ellipsis),
        if (stack.isNotEmpty) ExpansionTile(tilePadding: EdgeInsets.zero, title: const Text('Stack trace', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)), children: [Container(width: double.infinity, padding: const EdgeInsets.all(8), color: AppColors.surfaceAlt, child: SelectableText(stack, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')))]),
      ]),
    );
  }
}
