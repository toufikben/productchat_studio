import 'package:flutter/services.dart';

class ShortcutHandlerService {
  static const _channel = MethodChannel('com.productchat/shortcut_intent');
  static void Function(String type)? _handler;

  static void init(void Function(String type) handler) {
    try {
      _handler = handler;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onShortcut' && call.arguments is String) {
          try {
            _handler?.call(call.arguments as String);
          } catch (_) {
            // Native shortcut callbacks are optional and must be non-fatal.
          }
        }
        return null;
      });
    } catch (_) {
      _handler = null;
    }
  }

  static void handle(String type) {
    try {
      _handler?.call(type);
    } catch (_) {
      // Shortcut actions are optional and must never crash the app.
    }
  }
}
