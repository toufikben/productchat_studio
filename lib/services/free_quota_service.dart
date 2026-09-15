import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants.dart';
import 'storage_service.dart';

class FreeQuotaService extends StateNotifier<QuotaState> {
  FreeQuotaService({StorageService? storage})
      : _storage = storage,
        super(const QuotaState()) {
    _load();
  }
  static const _box = 'settings';
  static const _kUsed = 'free_quota_used';
  static const _kLastReset = 'free_quota_last_reset';
  static const monthKey = _kLastReset;
  static const usedKey = _kUsed;
  final StorageService? _storage;
  dynamic _get(String key, [dynamic fallback]) => _storage != null
      ? (_storage!.get(key) ?? fallback)
      : Hive.box<dynamic>(_box).get(key, defaultValue: fallback);
  Future<void> _put(String key, dynamic value) => _storage != null
      ? _storage!.set(key, value)
      : Hive.box<dynamic>(_box).put(key, value);
  void _load() {
    final raw = _get(_kLastReset) as String?;
    final now = DateTime.now();
    if (raw == null || _shouldReset(raw, now)) {
      _reset(now);
      return;
    }
    final used =
        (_get(_kUsed, 0) as int).clamp(0, AppConstants.freeMonthlyQuota);
    state = QuotaState(used: used, lastReset: DateTime.parse(raw));
  }

  bool _shouldReset(String value, DateTime now) {
    try {
      final monthParts = value.split('-');
      if (monthParts.length == 2) {
        final year = int.parse(monthParts[0]);
        final month = int.parse(monthParts[1]);
        return year != now.year || month != now.month;
      }
      final last = DateTime.parse(value);
      return last.month != now.month || last.year != now.year;
    } catch (_) {
      return true;
    }
  }

  void _reset(DateTime now) {
    _put(_kUsed, 0);
    _put(_kLastReset, now.toIso8601String());
    state = QuotaState(used: 0, lastReset: now);
  }

  void checkReset() {
    final raw = _get(_kLastReset) as String?;
    if (raw == null || _shouldReset(raw, DateTime.now()))
      _reset(DateTime.now());
  }

  bool canUse({bool isPro = false}) {
    if (isPro) return true;
    checkReset();
    return remaining > 0;
  }

  Future<bool> consume({int images = 1}) async {
    if (images <= 0 || !canUse() || images > remaining) return false;
    final next = used + images;
    await _put(_kUsed, next);
    state = state.copyWith(used: next);
    return true;
  }

  Future<void> forceReset() async {
    final now = DateTime.now();
    await _put(_kUsed, 0);
    await _put(_kLastReset, now.toIso8601String());
    state = QuotaState(used: 0, lastReset: now);
  }

  int get used => state.used;
  int get remaining => (AppConstants.freeMonthlyQuota - used).clamp(0, 999);
  String get month =>
      '${state.lastReset.year.toString().padLeft(4, '0')}-${state.lastReset.month.toString().padLeft(2, '0')}';
  DateTime get nextReset {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }
}

class QuotaState {
  final int used;
  final DateTime lastReset;
  const QuotaState({this.used = 0, DateTime? lastReset})
      : lastReset = lastReset ?? const _EpochDate();
  int get remaining => (AppConstants.freeMonthlyQuota - used).clamp(0, 999);
  DateTime get nextReset =>
      DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
  QuotaState copyWith({int? used, DateTime? lastReset}) => QuotaState(
      used: used ?? this.used, lastReset: lastReset ?? this.lastReset);
}

class _EpochDate implements DateTime {
  const _EpochDate();
  @override
  dynamic noSuchMethod(Invocation i) => DateTime(1970);
}

final freeQuotaProvider = StateNotifierProvider<FreeQuotaService, QuotaState>(
    (_) => FreeQuotaService());
