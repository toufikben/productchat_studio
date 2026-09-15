import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class PromoCode {
  final String code;
  final String type; // 'credits', 'discount', 'free_pro'
  final int value;
  final DateTime? expiresAt;
  final int? maxUses;
  final int? currentUses;

  const PromoCode({
    required this.code,
    required this.type,
    required this.value,
    this.expiresAt,
    this.maxUses,
    this.currentUses,
  });
}

class PromoResult {
  final bool ok;
  final String message;
  final PromoCode? code;
  const PromoResult({required this.ok, required this.message, this.code});
}

/// PromoCodeService — يدير أكواد الخصم والعروض.
///
/// ⚠️ ملاحظة أمنية: التحقق الحقيقي يحتاج خادماً.
/// هذا التحقق محلي للنسخة الأولية فقط.
class PromoCodeService {
  static const _box = 'promos';
  static const _usedKey = 'used_promos';

  /// أكواد افتراضية (يمكن تحديثها محلياً أو من الخادم لاحقاً).
  static const _builtInCodes = <String, PromoCode>{
    'WELCOME10': PromoCode(
      code: 'WELCOME10',
      type: 'credits',
      value: 10,
    ),
    'LAUNCH50': PromoCode(
      code: 'LAUNCH50',
      type: 'credits',
      value: 50,
    ),
    'PRO7DAY': PromoCode(
      code: 'PRO7DAY',
      type: 'free_pro',
      value: 7, // 7 days
    ),
    'SAVE20': PromoCode(
      code: 'SAVE20',
      type: 'discount',
      value: 20, // 20%
    ),
  };

  Future<PromoResult> redeem(String code) async {
    final normalized = code.trim().toUpperCase();

    if (normalized.isEmpty) {
      return const PromoResult(ok: false, message: 'Enter a code');
    }

    final used = List<String>.from(Hive.box<dynamic>('settings').get(_usedKey, defaultValue: []) as List);
    if (used.contains(normalized)) {
      return const PromoResult(ok: false, message: 'Code already used');
    }

    final promo = _builtInCodes[normalized];
    if (promo == null) {
      return const PromoResult(ok: false, message: 'Invalid code');
    }

    // ─── فحص الصلاحية ───
    if (promo.expiresAt != null && DateTime.now().isAfter(promo.expiresAt!)) {
      return const PromoResult(ok: false, message: 'Code expired');
    }

    // ─── تطبيق المكافأة ───
    switch (promo.type) {
      case 'credits':
        final credits = Hive.box<dynamic>('credits');
        final current = credits.get('balance', defaultValue: 0) as int;
        await credits.put('balance', current + promo.value);
        break;
      case 'free_pro':
        // تفعيل Pro لعدد أيام
        final settings = Hive.box<dynamic>('settings');
        await settings.put('isPro', true);
        final expiry = DateTime.now().add(Duration(days: promo.value));
        await settings.put('proExpiry', expiry.toIso8601String());
        break;
      case 'discount':
        // حفظ الخصم لتطبيقه في الدفع
        await Hive.box<dynamic>('settings').put('active_discount', promo.value);
        break;
    }

    // ─── تسجيل الاستخدام ───
    used.add(normalized);
    await Hive.box<dynamic>('settings').put(_usedKey, used);

    return PromoResult(
      ok: true,
      message: _successMessage(promo),
      code: promo,
    );
  }

  String _successMessage(PromoCode promo) {
    switch (promo.type) {
      case 'credits': return '+${promo.value} credits added';
      case 'free_pro': return 'Pro activated for ${promo.value} days';
      case 'discount': return '${promo.value}% discount applied';
      default: return 'Code applied';
    }
  }

  int getUsedCount() =>
      (Hive.box<dynamic>('settings').get(_usedKey, defaultValue: []) as List).length;

  Future<void> clearHistory() async {
    await Hive.box<dynamic>('settings').put(_usedKey, <String>[]);
  }

  /// توليد كود جديد (للمطورين).
  String generateCode({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final uuid = const Uuid().v4().replaceAll('-', '');
    return uuid.substring(0, length).toUpperCase();
  }
}
