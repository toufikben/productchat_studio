import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../models/edit_request.dart';

/// QwenEditService — On-device conversational AI editing via MethodChannel.
/// Replaces DreamLite (which has non-commercial CC BY-NC license).
///
/// Qwen-Image-Edit is Apache 2.0 — fully commercial.
class QwenEditService {
  static const _channel = MethodChannel('com.productchat/qwen_edit');

  Future<void> ensureLoaded() async {
    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/models/qwen_edit_int8.onnx';
    if (!await File(modelPath).exists()) {
      throw StateError('Qwen-Image-Edit model not downloaded');
    }
    await _channel.invokeMethod('loadModel', {'modelPath': modelPath});
  }

  Future<EditResult> run(EditRequest req, String inputPath) async {
    final sw = Stopwatch()..start();
    try {
      await ensureLoaded();
      final out = await _channel.invokeMapMethod<String, dynamic>('edit', {
        'imagePath': inputPath,
        'prompt': req.prompt ?? '',
        'operation': req.op.name,
      });
      if (out == null || out['ok'] != true) {
        return EditResult(ok: false, error: out?['error']?.toString() ?? 'Failed');
      }
      return EditResult(
        ok: true,
        outputPath: out['outputPath'] as String,
        creditsUsed: 3,
        duration: sw.elapsed,
      );
    } on PlatformException catch (e) {
      return EditResult(ok: false, error: e.message);
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }
}
