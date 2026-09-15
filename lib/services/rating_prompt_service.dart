import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

/// RatingPromptService — Smart in-app review prompt.
///
/// Rules:
///   • Show after 5 successful operations
///   • Show after at least 3 days since install
///   • Do not show more than once every 90 days
///   • Do not show if user already rated
class RatingPromptService {
  static const _keyOpCount = 'rating_op_count';
  static const _keyLastPrompt = 'rating_last_prompt';
  static const _keyRated = 'rating_done';
  static const _keyInstallDate = 'install_date';

  static const _minOps = 5;
  static const _minDays = 3;
  static const _promptCooldown = Duration(days: 90);

  /// Should we show the rating prompt now?
  static bool shouldPrompt() {
    final box = Hive.box<dynamic>('settings');

    if (box.get(_keyRated, defaultValue: false) as bool) return false;

    final opCount = box.get(_keyOpCount, defaultValue: 0) as int;
    if (opCount < _minOps) return false;

    final installStr = box.get(_keyInstallDate) as String?;
    if (installStr != null) {
      final installed = DateTime.tryParse(installStr);
      if (installed != null &&
          DateTime.now().difference(installed).inDays < _minDays) {
        return false;
      }
    }

    final lastStr = box.get(_keyLastPrompt) as String?;
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null &&
          DateTime.now().difference(last) < _promptCooldown) {
        return false;
      }
    }

    return true;
  }

  /// Track successful operation.
  static Future<void> trackOperation() async {
    final box = Hive.box<dynamic>('settings');
    final current = box.get(_keyOpCount, defaultValue: 0) as int;
    await box.put(_keyOpCount, current + 1);
  }

  /// Mark install date (call once on first launch).
  static Future<void> recordInstallDate() async {
    final box = Hive.box<dynamic>('settings');
    if (!box.containsKey(_keyInstallDate)) {
      await box.put(_keyInstallDate, DateTime.now().toIso8601String());
    }
  }

  /// Show the in-app review.
  static Future<bool> requestReview() async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
      await Hive.box<dynamic>('settings').put(_keyLastPrompt, DateTime.now().toIso8601String());
      return true;
    }
    return false;
  }

  /// Mark as rated (user tapped "Rate" in manual prompt).
  static Future<void> markRated() async {
    await Hive.box<dynamic>('settings').put(_keyRated, true);
  }
}
