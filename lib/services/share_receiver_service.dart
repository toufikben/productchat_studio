import 'package:flutter/services.dart';

/// ShareReceiverService — يستقبل الصور المُشاركة من تطبيقات أخرى.
class ShareReceiverService {
  static const _channel = MethodChannel('com.productchat/share');

  /// فحص إذا كان هناك صورة مُشاركة عند بدء التطبيق.
  Future<String?> getPendingImage() async {
    try {
      final path = await _channel.invokeMethod<String>('getPendingImage');
      return path;
    } catch (_) {
      return null;
    }
  }
}
