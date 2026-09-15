import 'package:hive_flutter/hive_flutter.dart';
class PaymentRecord {
  final String id;
  final String productId;
  final String productName;
  final double amount;
  final String currency;
  final String status; // 'completed', 'refunded', 'pending'
  final DateTime date;

  const PaymentRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'amount': amount,
    'currency': currency,
    'status': status,
    'date': date.toIso8601String(),
  };

  factory PaymentRecord.fromMap(Map m) => PaymentRecord(
    id: m['id'] ?? '',
    productId: m['productId'] ?? '',
    productName: m['productName'] ?? '',
    amount: (m['amount'] ?? 0).toDouble(),
    currency: m['currency'] ?? 'USD',
    status: m['status'] ?? 'completed',
    date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
  );
}

/// PaymentHistoryService — سجل المدفوعات.
class PaymentHistoryService {
  static const _box = 'payments';

  Future<void> add(PaymentRecord record) async {
    await Hive.box(_box).add(record.toMap());
  }

  List<PaymentRecord> getAll() {
    return Hive.box(_box).values
        .map((e) => PaymentRecord.fromMap(Map.from(e as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getTotalSpent() => getAll()
      .where((r) => r.status == 'completed')
      .fold(0.0, (sum, r) => sum + r.amount);

  Future<void> clear() => Hive.box(_box).clear();
}
