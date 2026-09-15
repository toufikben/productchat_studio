import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum HapticType { light, medium, heavy, selection, success, warning, error }

class HapticsService {
  static bool get _enabled =>
      Hive.box('settings').get('haptics', defaultValue: true) as bool;

  static Future<void> fire(HapticType type) async {
    if (!_enabled) return;
    try {
      switch (type) {
        case HapticType.light: await HapticFeedback.lightImpact();
        case HapticType.medium: await HapticFeedback.mediumImpact();
        case HapticType.heavy: await HapticFeedback.heavyImpact();
        case HapticType.selection: await HapticFeedback.selectionClick();
        case HapticType.success:
          await HapticFeedback.mediumImpact();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await HapticFeedback.lightImpact();
        case HapticType.warning: await HapticFeedback.heavyImpact();
        case HapticType.error:
          await HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  static Future<void> toggle(bool enabled) => Hive.box('settings').put('haptics', enabled);
  static bool get isEnabled => _enabled;
}
