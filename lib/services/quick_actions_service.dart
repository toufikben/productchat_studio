import 'package:flutter/services.dart';

class QuickActionsService {
  static const _channel = MethodChannel('com.productchat/quick_actions');

  static Future<void> init({required void Function(String type) onAction}) async {
    try {
      await _channel.invokeMethod('setShortcuts', {
        'shortcuts': [
          {'type': 'new_edit', 'icon': 'add_photo', 'title': 'New Edit', 'subtitle': 'Start a new photo edit'},
          {'type': 'batch', 'icon': 'layers', 'title': 'Batch Process', 'subtitle': 'Process multiple images'},
          {'type': 'history', 'icon': 'history', 'title': 'History', 'subtitle': 'View recent edits'},
          {'type': 'scan', 'icon': 'camera', 'title': 'Quick Scan', 'subtitle': 'Capture and edit'},
        ],
      });
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onShortcut' && call.arguments is String) {
          try {
            onAction(call.arguments as String);
          } catch (_) {
            // A shortcut callback must never terminate the app.
          }
        }
        return null;
      });
    } catch (_) {}
  }

  static Future<void> clear() async {
    try { await _channel.invokeMethod('clearShortcuts'); } catch (_) {}
  }
}
