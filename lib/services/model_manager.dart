import 'dart:async';
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

class ModelManager {
  static const _models = {
    'migan.onnx': AppConstants.modelMiganUrl,
    'lama_fp16.onnx': AppConstants.modelLamaUrl,
    'real_esrgan_x4.onnx': AppConstants.modelRealEsrganUrl,
  };

  static const lama = ModelSpec(
      id: 'lama',
      url: AppConstants.modelLamaUrl,
      fileName: 'lama_fp16.onnx',
      sha256: AppConstants.modelLamaSha256);
  static const realEsrgan = ModelSpec(
      id: 'real_esrgan',
      url: AppConstants.modelRealEsrganUrl,
      fileName: 'real_esrgan_x4.onnx',
      sha256: AppConstants.modelRealEsrganSha256);
  static const migan = ModelSpec(
      id: 'migan',
      url: AppConstants.modelMiganUrl,
      fileName: 'migan.onnx',
      sha256: AppConstants.modelMiganSha256);
  final Dio _dio;
  final Future<Directory> Function()? _directoryProvider;

  ModelManager({Dio? dio, Future<Directory> Function()? directoryProvider})
      : _dio = dio ??
            Dio(BaseOptions(
                receiveTimeout: const Duration(minutes: 15),
                connectTimeout: const Duration(seconds: 30))),
        _directoryProvider = directoryProvider;

  Future<Directory> _modelsDir() async {
    final dir =
        await (_directoryProvider?.call() ?? getApplicationSupportDirectory());
    final models = Directory('${dir.path}/models');
    if (!await models.exists()) await models.create(recursive: true);
    return models;
  }

  Future<File> modelFile(ModelSpec model) async {
    final dir = await _modelsDir();
    return File('${dir.path}/${model.fileName}');
  }

  Future<bool> isReady(ModelSpec model) async {
    final file = await modelFile(model);
    if (!await file.exists()) return false;
    final expected = model.sha256;
    if (expected.isEmpty || expected == 'REPLACE_AFTER_UPLOAD') return true;
    return _verifySha256(file, expected);
  }

  Future<File> download(String name,
      {void Function(double)? onProgress, CancelToken? cancelToken}) async {
    final dir = await _modelsDir();
    final target = File('${dir.path}/$name');
    final part = File('${dir.path}/$name.part');
    if (await target.exists()) {
      onProgress?.call(1.0);
      return target;
    }
    final url = _models[name];
    if (url == null) throw StateError('Unknown model: $name');
    var startByte = await part.exists() ? await part.length() : 0;
    var response = await _dio.get<ResponseBody>(url,
        options: Options(
            responseType: ResponseType.stream,
            headers: startByte > 0 ? {'Range': 'bytes=$startByte-'} : null),
        cancelToken: cancelToken);
    if (startByte > 0 && response.statusCode == HttpStatus.ok) {
      await part.delete();
      startByte = 0;
      response = await _dio.get<ResponseBody>(url,
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken);
    }
    final totalBytes =
        int.tryParse(response.headers.value('content-length') ?? '') ?? 0;
    final sink =
        part.openWrite(mode: startByte > 0 ? FileMode.append : FileMode.write);
    var received = startByte;
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0)
          onProgress?.call(received / (totalBytes + startByte));
      }
      await sink.close();
    } catch (_) {
      await sink.close();
      rethrow;
    }
    final expectedSha = _shaFor(name);
    if (expectedSha.isNotEmpty &&
        expectedSha != 'REPLACE_AFTER_UPLOAD' &&
        !await _verifySha256(part, expectedSha)) {
      await part.delete();
      throw StateError('SHA-256 mismatch for $name');
    }
    if (await target.exists()) await target.delete();
    await part.rename(target.path);
    onProgress?.call(1.0);
    return target;
  }

  String _shaFor(String name) {
    if (name.contains('migan')) return AppConstants.modelMiganSha256;
    if (name.contains('lama')) return AppConstants.modelLamaSha256;
    if (name.contains('esrgan')) return AppConstants.modelRealEsrganSha256;
    return '';
  }

  Future<bool> _verifySha256(File file, String expected) async {
    try {
      final digest = await sha256.bind(file.openRead()).first;
      return digest.toString().toLowerCase() == expected.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isCached(String name) async =>
      File('${(await _modelsDir()).path}/$name').exists();

  Future<Map<String, bool>> cacheStatus() async =>
      {for (final n in _models.keys) n: await isCached(n)};

  Future<void> deleteModel(String name) async =>
      delete(ModelSpec(id: name, url: '', fileName: name, sha256: ''));

  Future<void> delete(ModelSpec model) async {
    final dir = await _modelsDir();
    final file = File('${dir.path}/${model.fileName}');
    final part = File('${dir.path}/${model.fileName}.part');
    if (await file.exists()) await file.delete();
    if (await part.exists()) await part.delete();
  }

  Future<void> clearAll() async {
    final dir = await _modelsDir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<String?> readyPath(Object modelKey) async {
    final name =
        modelKey is ModelSpec ? modelKey.fileName : modelKey.toString();
    final file = File('${(await _modelsDir()).path}/$name');
    return await file.exists() ? file.path : null;
  }
}
