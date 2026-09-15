import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Analytics')), body: ValueListenableBuilder(valueListenable: Hive.box('analytics').listenable(), builder: (_, box, __) { final counts = <String,int>{}; for (final raw in box.values) { if (raw is Map) { final e = raw['event'] as String? ?? 'unknown'; counts[e] = (counts[e] ?? 0) + 1; } } final entries = counts.entries.toList()..sort((a,b) => b.value.compareTo(a.value)); return ListView(padding: const EdgeInsets.all(16), children: [Row(children: [Expanded(child: _Stat('Total events','${box.length}',AppColors.primary)), const SizedBox(width: 12), Expanded(child: _Stat('Event types','${counts.length}',AppColors.success))]), const SizedBox(height: 24), ...entries.map((e) => Card(child: ListTile(title: Text(e.key), trailing: Text('${e.value}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))))]; }));
}
class _Stat extends StatelessWidget { final String label,value; final Color color; const _Stat(this.label,this.value,this.color); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface,borderRadius: BorderRadius.circular(16),border: Border.all(color: AppColors.border)), child: Column(children: [Text(value,style: TextStyle(color: color,fontSize: 24,fontWeight: FontWeight.bold)), Text(label,style: const TextStyle(color: AppColors.textSecondary,fontSize: 12))])); }
