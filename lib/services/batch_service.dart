import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/edit_request.dart';
import '../models/edit_result.dart';
import 'ai_service.dart';
import 'billing_service.dart';
import 'history_service.dart';

typedef BatchProcessor = Future<EditResult> Function(String imagePath, EditOp operation);

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
  BatchService({BatchProcessor? processor, bool? isPro})
      : _processor = processor ?? AiService().apply,
        _isProOverride = isPro,
        super(const BatchProgress());

  final BatchProcessor _processor;
  final bool? _isProOverride;

  bool get _isPro => _isProOverride ?? billingService.proService.isPro;

  Future<void> processAll(
    List<String> inputs, {
    bool addShadow = false,
    String format = 'jpg',
    int size = 2000,
  }) async {
    if (state.running) return;
    if (!_isPro) {
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
    final operation = addShadow ? EditOp.shadow : EditOp.removeBg;
    for (var i = 0; i < jobs.length; i++) {
      try {
        final source = File(jobs[i].input);
        if (!await source.exists()) throw StateError('Input not found');
        final result = await _processor(jobs[i].input, operation);
        if (!result.ok || result.outputPath == null) {
          throw StateError(result.error ?? 'Image operation failed');
        }
        jobs[i] = BatchJob(input: jobs[i].input, output: result.outputPath);
        await historyService.record(
          path: result.outputPath!,
          operation: operation.name,
        );
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
