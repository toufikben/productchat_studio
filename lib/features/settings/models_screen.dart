import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/app_widgets.dart';

enum ModelState { notDownloaded, downloading, verifying, ready, failed }

class ModelInfo {
  final String id;
  final String name;
  final String size;
  final String description;
  final String url;
  final String fileName;
  final String sha256;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.description,
    required this.url,
    required this.fileName,
    required this.sha256,
  });
}

const kModels = <ModelInfo>[
  ModelInfo(
    id: 'lama',
    name: 'LaMa',
    size: '~208 MB',
    description: 'Inpainting — remove objects, fill areas',
    url: AppConstants.modelLamaUrl,
    fileName: 'lama_fp16.onnx',
    sha256: '',
  ),
  ModelInfo(
    id: 'real_esrgan',
    name: 'Real-ESRGAN',
    size: '~64 MB',
    description: 'Upscale 4× — enhance low-quality images',
    url: AppConstants.modelRealEsrganUrl,
    fileName: 'real_esrgan_x4.onnx',
    sha256: AppConstants.modelRealEsrganSha256,
  ),
];

class ModelCenterState {
  final Map<String, ModelState> states;
  final Map<String, double> progress;
  final Map<String, String> paths;
  final Map<String, String> errors;

  const ModelCenterState({
    this.states = const {},
    this.progress = const {},
    this.paths = const {},
    this.errors = const {},
  });

  ModelCenterState copyWith({
    Map<String, ModelState>? states,
    Map<String, double>? progress,
    Map<String, String>? paths,
    Map<String, String>? errors,
  }) =>
      ModelCenterState(
        states: states ?? this.states,
        progress: progress ?? this.progress,
        paths: paths ?? this.paths,
        errors: errors ?? this.errors,
      );
}

class ModelCenter extends StateNotifier<ModelCenterState> {
  ModelCenter() : super(const ModelCenterState()) {
    _scan();
  }

  final _dio = Dio(BaseOptions(
    receiveTimeout: const Duration(minutes: 15),
    connectTimeout: const Duration(seconds: 30),
  ));
  final _tokens = <String, CancelToken>{};

  Future<Directory> _dir() async {
    final d = await getApplicationSupportDirectory();
    final models = Directory('${d.path}/models');
    if (!await models.exists()) await models.create(recursive: true);
    return models;
  }

  Future<void> _scan() async {
    final states = <String, ModelState>{};
    final paths = <String, String>{};
    final d = await _dir();
    for (final m in kModels) {
      final f = File('${d.path}/${m.fileName}');
      if (await f.exists()) {
        states[m.id] = ModelState.ready;
        paths[m.id] = f.path;
      } else {
        states[m.id] = ModelState.notDownloaded;
      }
    }
    if (mounted) state = state.copyWith(states: states, paths: paths);
  }

  Future<void> download(String id) async {
    final model = kModels.firstWhere((m) => m.id == id);
    if (_tokens.containsKey(id)) return;

    final d = await _dir();
    final target = File('${d.path}/${model.fileName}');
    final part = File('${d.path}/${model.fileName}.part');

    final token = CancelToken();
    _tokens[id] = token;
    _update(id, ModelState.downloading, 0.0);

    try {
      await _dio.download(
        model.url,
        part.path,
        cancelToken: token,
        onReceiveProgress: (r, t) {
          if (t > 0) _update(id, ModelState.downloading, r / t);
        },
      );

      _update(id, ModelState.verifying, 1.0);
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      _update(id, ModelState.ready, 1.0, path: target.path);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        _update(id, ModelState.notDownloaded, 0.0);
      } else {
        _update(id, ModelState.failed, 0.0, error: '$e');
      }
    } finally {
      _tokens.remove(id);
    }
  }

  Future<void> cancel(String id) async {
    _tokens[id]?.cancel('user');
  }

  Future<void> delete(String id) async {
    final model = kModels.firstWhere((m) => m.id == id);
    final d = await _dir();
    final f = File('${d.path}/${model.fileName}');
    final p = File('${d.path}/${model.fileName}.part');
    if (await f.exists()) await f.delete();
    if (await p.exists()) await p.delete();
    _update(id, ModelState.notDownloaded, 0.0);
  }

  void _update(String id, ModelState s, double p,
      {String? path, String? error}) {
    if (!mounted) return;
    final states = Map<String, ModelState>.from(state.states);
    final progress = Map<String, double>.from(state.progress);
    final paths = Map<String, String>.from(state.paths);
    final errors = Map<String, String>.from(state.errors);
    states[id] = s;
    progress[id] = p;
    if (path != null) paths[id] = path;
    if (error != null) errors[id] = error;
    state = state.copyWith(
        states: states, progress: progress, paths: paths, errors: errors);
  }
}

final modelCenterProvider =
    StateNotifierProvider<ModelCenter, ModelCenterState>(
  (_) => ModelCenter(),
);

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(modelCenterProvider);
    final ready =
        state.states.values.where((s) => s == ModelState.ready).length;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Models')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryGlow],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                AppIcons.circle(Icons.memory, size: 48, color: Colors.white),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$ready of ${kModels.length} ready',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(height: 4),
                      const Text('Download only what you need',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kModels.length,
              itemBuilder: (_, i) {
                final m = kModels[i];
                return _ModelCard(
                  model: m,
                  state: state.states[m.id] ?? ModelState.notDownloaded,
                  progress: state.progress[m.id] ?? 0.0,
                  error: state.errors[m.id],
                  onDownload: () =>
                      ref.read(modelCenterProvider.notifier).download(m.id),
                  onCancel: () =>
                      ref.read(modelCenterProvider.notifier).cancel(m.id),
                  onDelete: () =>
                      ref.read(modelCenterProvider.notifier).delete(m.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final ModelInfo model;
  final ModelState state;
  final double progress;
  final String? error;
  final VoidCallback onDownload, onCancel, onDelete;

  const _ModelCard({
    required this.model,
    required this.state,
    required this.progress,
    this.error,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state == ModelState.ready
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: state == ModelState.ready ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppIcons.outline(
                Icons.healing,
                size: 48,
                color: state == ModelState.ready
                    ? AppColors.success
                    : AppColors.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(model.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(width: 8),
                        if (state == ModelState.ready)
                          _badge('Ready', AppColors.success),
                        if (state == ModelState.failed)
                          _badge('Failed', AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(model.description,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(model.size,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              _actionButton(),
            ],
          ),
          if (state == ModelState.downloading ||
              state == ModelState.verifying) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(
                  state == ModelState.verifying
                      ? AppColors.warning
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _actionButton() {
    switch (state) {
      case ModelState.downloading:
      case ModelState.verifying:
        return IconButton(
          icon: const Icon(Icons.close, color: AppColors.danger),
          onPressed: onCancel,
        );
      case ModelState.ready:
        return IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          onPressed: onDelete,
        );
      case ModelState.failed:
      case ModelState.notDownloaded:
        return FilledButton.tonal(
          onPressed: onDownload,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Download'),
        );
    }
  }
}
