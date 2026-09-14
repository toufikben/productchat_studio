import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import 'storage_service.dart';

/// Durable local counter for the Free monthly image quota.
/// The counter is intentionally separate from Credits: a Free user cannot
/// bypass the monthly product quota by buying a Credits pack.
class FreeQuotaService extends ChangeNotifier {
  FreeQuotaService({StorageService? storage}) : _storage = storage ?? storageService {
    _load();
  }

  static const monthKey = 'free.quota.month';
  static const usedKey = 'free.quota.used';

  final StorageService _storage;
  String _month = _currentMonth();
  int _used = 0;

  String get month => _month;
  int get used => _used;
  int get remaining =>
      (AppConstants.freeMonthlyQuota - _used).clamp(0, AppConstants.freeMonthlyQuota);
  bool get exhausted => remaining == 0;

  bool canUse({int images = 1}) => images > 0 && remaining >= images;

  Future<bool> consume({int images = 1}) async {
    if (!canUse(images: images)) return false;
    _used += images;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> resetForTesting({String? month, int used = 0}) async {
    _month = month ?? _currentMonth();
    _used = used.clamp(0, AppConstants.freeMonthlyQuota);
    await _persist();
    notifyListeners();
  }

  void _load() {
    final current = _currentMonth();
    final storedMonth = _storage.getString(monthKey);
    if (storedMonth == current) {
      _month = current;
      _used = (_storage.get(usedKey) as int? ?? 0)
          .clamp(0, AppConstants.freeMonthlyQuota);
    } else {
      _month = current;
      _used = 0;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _storage.set(monthKey, _month);
    await _storage.set(usedKey, _used);
  }

  static String _currentMonth() {
    final now = DateTime.now().toUtc();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }
}
