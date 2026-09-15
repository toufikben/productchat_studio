import 'package:flutter/services.dart';

class ShortcutHandlerService {
  static const _channel = MethodChannel('com.productchat/shortcut_intent');
  static void Function(String type)? _handler;

  static void init(void Function(String type) handler) {
    _handler = handler;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShortcut' && call.arguments is String) {
        _handler?.call(call.arguments as String);
      }
      return null;
    });
  }

  static void handle(String type) => _handler?.call(type);
}
