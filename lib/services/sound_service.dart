import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum SoundEffect { click, success, error, notification, whoosh }

class SoundService {
  static bool get _enabled =>
      Hive.box('settings').get('sound', defaultValue: true) as bool;

  static Future<void> play(SoundEffect effect) async {
    if (!_enabled) return;
    try {
      switch (effect) {
        case SoundEffect.click:
        case SoundEffect.whoosh:
          await SystemSound.play(SystemSoundType.click);
        case SoundEffect.success:
        case SoundEffect.error:
        case SoundEffect.notification:
          await SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  static Future<void> toggle(bool enabled) => Hive.box('settings').put('sound', enabled);
  static bool get isEnabled => _enabled;
}
