import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import 'billing_service.dart';

class BatchJob {
  final String input;
  final String? output;
  final String? error;
  const BatchJob({required this.input, this.output, this.error});
}

class BatchProgress {
  final List<BatchJob> jobs;
  final int completed;
  final bool running;
  final String? error;
  const BatchProgress({
    this.jobs = const [],
    this.completed = 0,
    this.running = false,
    this.error,
  });
  double get fraction => jobs.isEmpty ? 0 : completed / jobs.length;
}

class BatchService extends StateNotifier<BatchProgress> {
  BatchService() : super(const BatchProgress());

  Future<void> processAll(
    List<String> inputs, {
    bool addShadow = false,
    String format = 'jpg',
    int size = 2000,
  }) async {
    if (state.running) return;
    if (!billingService.proService.isPro) {
      state = const BatchProgress(error: 'Batch processing requires Pro or Lifetime.');
      return;
    }
    if (inputs.isEmpty) {
      state = const BatchProgress(error: 'Select at least one image.');
      return;
    }
    if (inputs.length > AppConstants.maxBatchImages) {
      state = const BatchProgress(
        error: 'Batch is limited to 100 images per operation.',
      );
      return;
    }

    final jobs = inputs.map((p) => BatchJob(input: p)).toList();
    state = BatchProgress(jobs: jobs, running: true);
    final dir = await getTemporaryDirectory();
    for (var i = 0; i < jobs.length; i++) {
      try {
        final source = File(jobs[i].input);
        if (!await source.exists()) throw StateError('Input not found');
        final ext = format == 'png' ? 'png' : 'jpg';
        final out = File(
          '${dir.path}/batch_${DateTime.now().microsecondsSinceEpoch}_$i.$ext',
        );
        await source.copy(out.path);
        jobs[i] = BatchJob(input: jobs[i].input, output: out.path);
      } catch (e) {
        jobs[i] = BatchJob(input: jobs[i].input, error: '$e');
      }
      state = BatchProgress(
        jobs: List.unmodifiable(jobs),
        completed: i + 1,
        running: i + 1 < jobs.length,
      );
    }
    state = BatchProgress(
      jobs: List.unmodifiable(jobs),
      completed: jobs.length,
      running: false,
    );
  }

  void reset() => state = const BatchProgress();
}

final batchProvider =
    StateNotifierProvider<BatchService, BatchProgress>((_) => BatchService());
