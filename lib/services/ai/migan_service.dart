import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/edit_request.dart';
import '../model_manager.dart';

/// MIGanService — On-device MI-GAN background removal (balanced quality).
class MIGanService {
  static const _channel = MethodChannel('com.productchat/seika');

  Future<bool> isModelReady() async {
    final path = await _modelPath();
    return path != null;
  }

  Future<String?> _modelPath() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/models/migan.onnx');
      return await file.exists() ? file.path : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> ensureLoaded() async {
    final path = await _modelPath();
    if (path == null) {
      throw StateError('MI-GAN model not downloaded');
    }
    await _channel.invokeMethod('loadModel', {
      'modelType': 'migan',
      'modelPath': path,
    });
  }

  Future<EditResult> removeBg(String inputPath) async {
    final sw = Stopwatch()..start();
    try {
      await ensureLoaded();
      final out = await _channel.invokeMapMethod<String, dynamic>('removeBg', {
        'path': inputPath,
        'quality': 'balanced',
      });
      if (out == null || out['ok'] != true) {
        return EditResult(
          ok: false,
          error: out?['error']?.toString() ?? 'MI-GAN failed',
        );
      }
      return EditResult(
        ok: true,
        outputPath: out['outputPath'] as String,
        creditsUsed: 2,
        duration: sw.elapsed,
      );
    } on PlatformException catch (e) {
      return EditResult(ok: false, error: '${e.code}: ${e.message}');
    } catch (e) {
      return EditResult(ok: false, error: '$e');
    }
  }
}
