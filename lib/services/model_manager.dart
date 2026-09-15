import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

class ModelSpec {
  final String id;
  final String url;
  final String fileName;
  final String sha256;

  const ModelSpec({
    required this.id,
    required this.url,
    required this.fileName,
    required this.sha256,
  });
}

class ModelDownloadProgress {
  final String modelId;
  final int received;
  final int total;
  final bool complete;

  const ModelDownloadProgress({
    required this.modelId,
    required this.received,
    required this.total,
    this.complete = false,
  });

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0, 1);
}

class ModelManager {
  static const lama = ModelSpec(
    id: 'lama',
    url: AppConstants.modelLamaUrl,
    fileName: 'lama_fp32.onnx',
    sha256:
        '1faef5301d78db7dda502fe59966957ec4b79dd64e16f03ed96913c7a4eb68d6',
  );

  /// Maximum number of times [download] will fall back to a full (non-Range)
  /// download when the server ignores the Range header. Prevents an infinite
  /// recursive loop on servers that persistently return 200 instead of 206.
  static const _maxRangeRetries = 1;

  final Dio _dio;
  final Future<Directory> Function() _directoryProvider;
  final Map<String, _VerifiedFile> _verifiedCache = {};

  ModelManager({Dio? dio, Future<Directory> Function()? directoryProvider})
      : _dio = dio ?? Dio(),
        _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory;

  Future<File> modelFile(ModelSpec model) async {
    final directory = await _directoryProvider();
    final modelsDirectory = Directory('\${directory.path}/models');
    await modelsDirectory.create(recursive: true);
    return File('\${modelsDirectory.path}/\${model.fileName}');
  }

  Future<bool> isReady(ModelSpec model) async {
    final file = await modelFile(model);
    if (!await file.exists()) return false;
    final length = await file.length();
    final modified = await file.lastModified();
    final cached = _verifiedCache[model.id];
    if (cached != null &&
        cached.path == file.path &&
        cached.length == length &&
        cached.modified == modified &&
        cached.sha256 == model.sha256) {
      return true;
    }
    final valid = await _matchesSha256(file, model.sha256);
    if (valid) {
      _verifiedCache[model.id] = _VerifiedFile(
        path: file.path,
        length: length,
        modified: modified,
        sha256: model.sha256,
      );
    } else {
      _verifiedCache.remove(model.id);
    }
    return valid;
  }

  Future<String?> readyPath(ModelSpec model) async {
    return await isReady(model) ? (await modelFile(model)).path : null;
  }

  Stream<ModelDownloadProgress> download(ModelSpec model,
      {int _rangeRetry = 0}) async* {
    if (await isReady(model)) {
      final file = await modelFile(model);
      yield ModelDownloadProgress(
          modelId: model.id,
          received: await file.length(),
          total: await file.length(),
          complete: true);
      return;
    }

    final file = await modelFile(model);
    final temporary = File('\${file.path}.part');
    var offset = await temporary.exists() ? await temporary.length() : 0;
    if (offset > 0) {
      try {
        final response = await _dio.head<void>(model.url);
        final total = int.tryParse(
            response.headers.value('content-length') ?? '');
        if (total != null && offset >= total) {
          await _finalize(temporary, file, model);
          yield ModelDownloadProgress(
              modelId: model.id,
              received: total,
              total: total,
              complete: true);
          return;
        }
      } catch (_) {
        offset = 0;
        if (await temporary.exists()) await temporary.delete();
      }
    }

    final response = await _dio.download(
      model.url,
      temporary.path,
      deleteOnError: false,
      fileAccessMode:
          offset > 0 ? FileAccessMode.append : FileAccessMode.write,
      options: Options(
        responseType: ResponseType.bytes,
        headers: offset > 0 ? {'Range': 'bytes=\$offset-'} : null,
      ),
      onReceiveProgress: (received, total) {
        // Progress is surfaced via the stream; this callback logs in native.
      },
    );

    if (offset > 0 && response.statusCode == HttpStatus.ok) {
      // The server ignored the Range header and sent the full file.
      // Retry once from byte zero to avoid a duplicated/corrupted artifact.
      if (_rangeRetry >= _maxRangeRetries) {
        throw StateError(
            'Server repeatedly ignored Range header for \${model.id}.');
      }
      await temporary.delete();
      yield* download(model, _rangeRetry: _rangeRetry + 1);
      return;
    }

    if (response.statusCode != null && response.statusCode! >= 400) {
      throw StateError(
          'Model download failed with HTTP \${response.statusCode}.');
    }

    final total = await temporary.length();
    yield ModelDownloadProgress(
        modelId: model.id, received: total, total: total);
    await _finalize(temporary, file, model);
    yield ModelDownloadProgress(
        modelId: model.id,
        received: total,
        total: total,
        complete: true);
  }

  Future<void> delete(ModelSpec model) async {
    final file = await modelFile(model);
    final temporary = File('\${file.path}.part');
    if (await file.exists()) await file.delete();
    if (await temporary.exists()) await temporary.delete();
    _verifiedCache.remove(model.id);
  }

  Future<void> _finalize(
      File temporary, File target, ModelSpec model) async {
    if (!await _matchesSha256(temporary, model.sha256)) {
      await temporary.delete();
      throw StateError(
          'SHA-256 mismatch for \${model.id}; download discarded.');
    }
    if (await target.exists()) await target.delete();
    await temporary.rename(target.path);
    _verifiedCache.remove(model.id);
  }

  Future<bool> _matchesSha256(File file, String expected) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase() == expected.toLowerCase();
  }
}

class _VerifiedFile {
  final String path;
  final int length;
  final DateTime modified;
  final String sha256;

  const _VerifiedFile({
    required this.path,
    required this.length,
    required this.modified,
    required this.sha256,
  });
}

String modelDownloadProgressToJson(ModelDownloadProgress progress) =>
    jsonEncode({
      'modelId': progress.modelId,
      'received': progress.received,
      'total': progress.total,
      'complete': progress.complete,
    });
