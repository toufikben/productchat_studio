import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/edit_request.dart';
import '../services/smart_analysis_service.dart';
class SmartAnalysisPanel extends StatelessWidget {
  final AnalysisResult result; final ValueChanged<EditOp> onSuggestionTap; final VoidCallback onDismiss;
  const SmartAnalysisPanel({super.key, required this.result, required this.onSuggestionTap, required this.onDismiss});
  @override Widget build(BuildContext context) { if (!result.ok || result.suggestions.isEmpty) return const SizedBox.shrink(); return Card(margin: const EdgeInsets.all(16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.auto_awesome, color: AppColors.primary), const SizedBox(width: 8), const Text('Smart Analysis', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(onPressed: onDismiss, icon: const Icon(Icons.close))]), ...result.suggestions.take(3).map((s) => ListTile(onTap: () => onSuggestionTap(s.op), leading: const Icon(Icons.lightbulb_outline, color: AppColors.primary), title: Text(s.title), subtitle: Text(s.description), trailing: const Icon(Icons.chevron_right)))]))); }
}
