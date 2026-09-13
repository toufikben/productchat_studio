import 'package:flutter/services.dart';
import '../models/edit_result.dart';

/// Local image operations backed by the Android/iOS Seika native bridge.
/// The bridge is intentionally explicit about masks: an image must never be
/// passed as its own mask because that produces undefined inpainting output.
class SeikaService {
  static const _channel = MethodChannel('productchat/studio/seika');

  Future<EditResult> inpaint(String imagePath, String maskPath) async {
    if (imagePath.isEmpty || maskPath.isEmpty) {
      return const EditResult.failure('An image path and a real mask path are required.');
    }
    try {
      final output = await _channel.invokeMethod<String>('inpaint', {
        'imagePath': imagePath,
        'maskPath': maskPath,
      });
      if (output == null || output.isEmpty) {
        return const EditResult.failure('Seika returned no output path.');
      }
      return EditResult(ok: true, outputPath: output, creditsUsed: 3);
    } on MissingPluginException {
      return const EditResult.failure('Seika native bridge is not implemented on this platform.');
    } on PlatformException catch (e) {
      return EditResult.failure('Seika inpaint failed: ${e.message ?? e.code}');
    }
  }

  Future<EditResult> conversationalEdit({
    required String imagePath,
    required String? maskPath,
    String? prompt,
  }) {
    if (maskPath == null || maskPath.isEmpty) {
      return Future.value(const EditResult.failure(
        'A mask is required for conversational object removal.',
      ));
    }
    return inpaint(imagePath, maskPath);
  }

  Future<EditResult> removeBackground(String imagePath) =>
      _invoke('removeBackground', {'imagePath': imagePath}, credits: 1);

  Future<EditResult> upscale(String imagePath, {required int factor}) =>
      _invoke('upscale', {'imagePath': imagePath, 'factor': factor}, credits: 2);

  Future<EditResult> addShadow(String imagePath) =>
      _invoke('addShadow', {'imagePath': imagePath}, credits: 1);

  Future<EditResult> export(String imagePath,
          {required String format, required int size}) =>
      _invoke('export', {
        'imagePath': imagePath,
        'format': format,
        'size': size,
      });

  Future<EditResult> _invoke(String method, Map<String, Object?> arguments,
      {int credits = 0}) async {
    try {
      final output = await _channel.invokeMethod<String>(method, arguments);
      if (output == null || output.isEmpty) {
        return EditResult.failure('Seika returned no output path for $method.');
      }
      return EditResult(ok: true, outputPath: output, creditsUsed: credits);
    } on MissingPluginException {
      return EditResult.failure(
          'Seika native bridge is not implemented on this platform.');
    } on PlatformException catch (e) {
      return EditResult.failure('$method failed: ${e.message ?? e.code}');
    }
  }
}
