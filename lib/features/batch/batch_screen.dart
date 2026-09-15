import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/batch_service.dart';
import '../../services/billing_service.dart';
import '../../core/feature_flags.dart';

class BatchScreen extends ConsumerWidget {
  const BatchScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(batchProvider);
    final service = ref.read(batchProvider.notifier);
    if (!FeatureFlags.batchProcessing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch processing')),
        body: const Center(child: Text('Batch processing is under development')),
      );
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Batch processing')),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(
                        billingService.proService.isPro
                            ? Icons.verified_outlined
                            : Icons.lock_outline,
                      ),
                      title: Text(
                        billingService.proService.isPro
                            ? 'Batch enabled'
                            : 'Batch requires Pro or Lifetime',
                      ),
                      subtitle: const Text('Up to 100 images per operation.'),
                    ),
                  ),
                  FilledButton.icon(
                      onPressed: p.running || !billingService.proService.isPro
                          ? null
                          : () async {
                              final picked = await FilePicker.platform
                                  .pickFiles(
                                      allowMultiple: true,
                                      type: FileType.image);
                              final paths = picked?.files
                                      .map((f) => f.path)
                                      .whereType<String>()
                                      .toList() ??
                                  [];
                              if (paths.isNotEmpty && context.mounted) {
                                final addShadow = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Choose batch operation'),
                                    content: const Text(
                                      'Select the same local operation for all chosen images.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: const Text('Remove background'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        child: const Text('Add shadow'),
                                      ),
                                    ],
                                  ),
                                );
                                if (addShadow != null) {
                                  await service.processAll(paths, addShadow: addShadow);
                                }
                              }
                            },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Select images')),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                      value: p.jobs.isEmpty ? 0 : p.fraction),
                  const SizedBox(height: 8),
                  if (p.error != null)
                    Text(
                      p.error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  Text('${p.completed} / ${p.jobs.length} completed'),
                  const SizedBox(height: 16),
                  Expanded(
                      child: ListView.builder(
                          itemCount: p.jobs.length,
                          itemBuilder: (_, i) {
                            final j = p.jobs[i];
                            return ListTile(
                                leading: Icon(
                                    j.error == null && j.output != null
                                        ? Icons.check_circle
                                        : Icons.image),
                                title: Text(j.input.split('/').last),
                                subtitle:
                                    Text(j.error ?? j.output ?? 'Waiting'));
                          })),
                  if (p.jobs.isNotEmpty && !p.running)
                    OutlinedButton(
                        onPressed: service.reset, child: const Text('Clear'))
                ])));
  }
}
