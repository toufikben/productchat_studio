import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/billing_service.dart';
import '../../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final isPro = billingService.proService.isPro;
    final entries = historyService.visible(isPro: isPro);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                await historyService.clear();
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No successful edits yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Card(
                  child: ListTile(
                    leading: File(entry.path).existsSync()
                        ? Image.file(File(entry.path), width: 56, height: 56, fit: BoxFit.cover)
                        : const Icon(Icons.broken_image_outlined),
                    title: Text(entry.operation),
                    subtitle: Text(entry.createdAt.toLocal().toString()),
                    trailing: IconButton(
                      tooltip: 'Delete history item',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await historyService.delete(entry);
                        if (mounted) setState(() {});
                      },
                    ),
                    onTap: () => context.push(
                      '/editor?imagePath=${Uri.encodeComponent(entry.path)}',
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: isPro
          ? null
          : const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Free shows the latest 5 successful edits. Pro and Lifetime unlock full history.',
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
