import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

class PriceABTestService {
  static const _key = 'ab_price_group';
  static const _variants = ['A', 'B', 'C'];

  static const prices = {
    'A': {'pro_monthly': 4.99, 'pro_yearly': 29.99, 'credits_100': 4.99, 'credits_500': 19.99, 'credits_1200': 39.99, 'lifetime': 79.99},
    'B': {'pro_monthly': 6.99, 'pro_yearly': 39.99, 'credits_100': 5.99, 'credits_500': 24.99, 'credits_1200': 49.99, 'lifetime': 99.99},
    'C': {'pro_monthly': 3.99, 'pro_yearly': 24.99, 'credits_100': 3.99, 'credits_500': 14.99, 'credits_1200': 29.99, 'lifetime': 59.99},
  };

  String getGroup() {
    final box = Hive.box('settings');
    var g = box.get(_key) as String?;
    if (g == null) {
      g = _variants[Random().nextInt(_variants.length)];
      box.put(_key, g);
    }
    return g;
  }

  double? priceFor(String productId) {
    final g = getGroup();
    return prices[g]?[productId]?.toDouble();
  }

  Future<void> logPurchase(String productId) async {
    final box = Hive.box('analytics');
    await box.add({
      'event': 'purchase',
      'params': {'group': getGroup(), 'product': productId},
      'ts': DateTime.now().toIso8601String(),
    });
  }

  Map<String, int> report() {
    final box = Hive.box('analytics');
    final counts = {'A': 0, 'B': 0, 'C': 0};
    for (final e in box.values) {
      final m = Map<String, dynamic>.from(e as Map);
      if (m['event'] == 'purchase') {
        final g = m['params']?['group'] as String?;
        if (g != null) counts[g] = (counts[g] ?? 0) + 1;
      }
    }
    return counts;
  }
}
