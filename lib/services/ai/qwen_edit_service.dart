import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/edit_request.dart';

/// QwenEditService — conversational image editing through a remote API.
///
/// Qwen-Image-Edit is a large server-side model.
///
/// The temporary client-side option accepts a Base64-encoded value through
/// `--dart-define=QWEN_API_KEY_B64=...`. Base64 is obfuscation, not encryption:
/// a distributed APK can still be inspected. The production option is a
/// Supabase Edge Function, where the real key remains server-side.
class QwenEditService {
  static String get _apiKey {
    const encoded = String.fromEnvironment('QWEN_API_KEY_B64');
    if (encoded.isNotEmpty) {
      try {
        return utf8.decode(base64.decode(encoded));
      } on FormatException {
        return '';
      }
    }
    // Backward-compatible local development path. Do not use in public APKs.
    return const String.fromEnvironment('QWEN_API_KEY');
  }
  static const _baseUrl =
      'https://api.wavespeed.ai/api/v3/wavespeed-ai/qwen-image-edit';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 3),
  ));

  Future<EditResult> run(EditRequest req, String inputPath) async {
    final sw = Stopwatch()..start();

    if (_apiKey.isEmpty) {
      return const EditResult(
        ok: false,
        error: 'Qwen API key not configured',
      );
    }

    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(inputPath),
        'prompt': req.prompt ?? 'Enhance product photo',
      });

      final response = await _dio.post<dynamic>(
        _baseUrl,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $_apiKey'},
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode != 200) {
        return EditResult(
          ok: false,
          error: 'API error: ${response.statusCode}',
        );
      }

      final taskId = response.data['data']?['id'];
      if (taskId == null) {
        return const EditResult(ok: false, error: 'No task ID returned');
      }

      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final poll = await _dio.get<dynamic>(
          '$_baseUrl/result/$taskId',
          options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
        );

        final data = poll.data['data'];
        final status = data?['status'];
        if (status == 'completed') {
          final imageUrl = data?['output']?.toString();
          if (imageUrl == null) {
            return const EditResult(ok: false, error: 'No output URL');
          }

          final outPath =
              inputPath.replaceFirst(RegExp(r'\.[^.]+$'), '_qwen.png');
          await _dio.download(imageUrl, outPath);
          return EditResult(
            ok: true,
            outputPath: outPath,
            creditsUsed: 3,
            duration: sw.elapsed,
          );
        }
        if (status == 'failed') {
          return const EditResult(ok: false, error: 'API processing failed');
        }
      }

      return const EditResult(ok: false, error: 'API timeout');
    } on DioException catch (e) {
      return EditResult(ok: false, error: 'Qwen API: ${e.message}');
    } catch (e) {
      return EditResult(ok: false, error: 'Qwen API: $e');
    }
  }

  Future<void> ensureLoaded() async {}

  Future<bool> isAvailable() async => _apiKey.isNotEmpty;
}
