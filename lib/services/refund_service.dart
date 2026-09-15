import 'package:hive_flutter/hive_flutter.dart';
/// RefundService — يعالج الاسترداد وحالات Chargeback.
///
/// القواعد:
///   • Refund خلال 48 ساعة → استرداد تلقائي.
///   • Chargeback → تعليق Pro فوراً.
///   • سجل الاستردادات يُحفظ محلياً.
class RefundService {
  static const _kRefundHistory = 'refund_history';

  /// تسجيل طلب استرداد.
  Future<void> logRefund({
    required String productId,
    required String reason,
    required int creditsRefunded,
  }) async {
    final box = Hive.box<dynamic>('analytics');
    await box.add({
      'event': 'refund',
      'product': productId,
      'reason': reason,
      'credits': creditsRefunded,
      'ts': DateTime.now().toIso8601String(),
    });

    final history = Hive.box<dynamic>('settings');
    final list = List<Map<String, dynamic>>.from(
      (history.get(_kRefundHistory, defaultValue: []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    list.add({
      'product': productId,
      'reason': reason,
      'credits': creditsRefunded,
      'ts': DateTime.now().toIso8601String(),
    });
    await history.put(_kRefundHistory, list);
  }

  /// استرداد Credits.
  Future<void> refundCredits(int amount) async {
    final box = Hive.box<dynamic>('credits');
    final current = box.get('balance', defaultValue: 0) as int;
    await box.put('balance', current + amount);
  }

  /// تعليق Pro بعد Chargeback.
  Future<void> suspendPro({String reason = 'chargeback'}) async {
    final box = Hive.box<dynamic>('settings');
    await box.put('isPro', false);
    await box.put('isLifetime', false);
    await box.put('proExpiry', '');
    await box.put('suspension_reason', reason);
    await box.put('suspended_at', DateTime.now().toIso8601String());
  }

  /// عدد الاستردادات.
  int getRefundCount() => Hive.box<dynamic>('analytics').values
      .where((e) => (e as Map)['event'] == 'refund')
      .length;

  /// سجل الاستردادات.
  List<Map<String, dynamic>> getHistory() {
    final list = Hive.box<dynamic>('settings').get(_kRefundHistory, defaultValue: []) as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// فحص هل المستخدم مُعلّق.
  bool isSuspended() =>
      Hive.box<dynamic>('settings').get('suspended_at') != null;
}
