import 'package:hive_flutter/hive_flutter.dart';

/// RateLimiterService — حماية محلية ضد الإساءة.
///
/// القيود:
///   • 30 عملية AI/دقيقة
///   • 200 عملية AI/ساعة
///   • 1000 عملية AI/يوم
class RateLimiterService {
  static const _boxName = 'rate_limits';
  static const _minuteWindow = 60; // seconds
  static const _hourWindow = 3600;
  static const _dayWindow = 86400;

  static const _minuteLimit = 30;
  static const _hourLimit = 200;
  static const _dayLimit = 1000;

  Box get _box => Hive.box(_boxName);

  /// فحص إذا كان مسموحاً بعملية جديدة.
  RateLimitCheck check() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Clean old entries
    _cleanup(now);

    final minuteCount = _countInWindow(now, _minuteWindow);
    final hourCount = _countInWindow(now, _hourWindow);
    final dayCount = _countInWindow(now, _dayWindow);

    if (dayCount >= _dayLimit) {
      return RateLimitCheck(
        allowed: false,
        reason: 'Daily limit reached ($_dayLimit)',
        retryAfterSeconds: _secondsUntilWindowClear(now, _dayWindow),
      );
    }
    if (hourCount >= _hourLimit) {
      return RateLimitCheck(
        allowed: false,
        reason: 'Hourly limit reached ($_hourLimit)',
        retryAfterSeconds: _secondsUntilWindowClear(now, _hourWindow),
      );
    }
    if (minuteCount >= _minuteLimit) {
      return RateLimitCheck(
        allowed: false,
        reason: 'Too fast — wait a moment',
        retryAfterSeconds: _secondsUntilWindowClear(now, _minuteWindow),
      );
    }

    return const RateLimitCheck(allowed: true);
  }

  /// سجّل عملية جديدة.
  Future<void> record() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _box.add(now);
  }

  /// حالة الاستخدام الحالي.
  UsageStats getStats() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return UsageStats(
      lastMinute: _countInWindow(now, _minuteWindow),
      lastHour: _countInWindow(now, _hourWindow),
      lastDay: _countInWindow(now, _dayWindow),
      minuteLimit: _minuteLimit,
      hourLimit: _hourLimit,
      dayLimit: _dayLimit,
    );
  }

  Future<void> clear() => _box.clear();

  // ═══════════════════════════════════════════════════════════════
  // Internal
  // ═══════════════════════════════════════════════════════════════

  int _countInWindow(int now, int windowSeconds) {
    final cutoff = now - windowSeconds;
    var count = 0;
    for (final value in _box.values) {
      if (value is int && value > cutoff) count++;
    }
    return count;
  }

  int _secondsUntilWindowClear(int now, int windowSeconds) {
    final cutoff = now - windowSeconds;
    int oldest = now;
    for (final value in _box.values) {
      if (value is int && value > cutoff) {
        if (value < oldest) oldest = value;
      }
    }
    return (oldest + windowSeconds) - now;
  }

  void _cleanup(int now) {
    final cutoff = now - _dayWindow;
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is int && value < cutoff) {
        keysToDelete.add(key);
      }
    }
    for (final key in keysToDelete) {
      _box.delete(key);
    }
  }
}

class RateLimitCheck {
  final bool allowed;
  final String? reason;
  final int? retryAfterSeconds;

  const RateLimitCheck({
    required this.allowed,
    this.reason,
    this.retryAfterSeconds,
  });
}

class UsageStats {
  final int lastMinute;
  final int lastHour;
  final int lastDay;
  final int minuteLimit;
  final int hourLimit;
  final int dayLimit;

  const UsageStats({
    required this.lastMinute,
    required this.lastHour,
    required this.lastDay,
    required this.minuteLimit,
    required this.hourLimit,
    required this.dayLimit,
  });

  double get minuteUsage => lastMinute / minuteLimit;
  double get hourUsage => lastHour / hourLimit;
  double get dayUsage => lastDay / dayLimit;
}
