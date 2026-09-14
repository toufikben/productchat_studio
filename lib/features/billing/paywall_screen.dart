import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../services/billing_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    billingService.init();
    billingService.addListener(_refresh);
  }

  @override
  void dispose() {
    billingService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Credits')),
        body: RefreshIndicator(
          onRefresh: billingService.restorePurchases,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bolt),
                  title: const Text('Available credits'),
                  trailing: Text('${billingService.credits}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              if (!billingService.available && billingService.error != null)
                Text(billingService.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (billingService.loading) const LinearProgressIndicator(),
              ...billingService.products.map(_productTile),
              if (billingService.available && billingService.products.isEmpty)
                const Text('No credit or subscription products are configured in Google Play yet.'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: billingService.available ? billingService.restorePurchases : null,
                icon: const Icon(Icons.restore),
                label: const Text('Restore purchases'),
              ),
              const SizedBox(height: 16),
              const Text('Purchases are completed by Google Play. Credits are added only after a purchased transaction with a valid transaction ID. Pending and failed purchases never add credits.'),
            ],
          ),
        ),
      );

  Widget _productTile(ProductDetails product) => Card(
        child: ListTile(
          title: Text(CreditProducts.isSubscription(product.id)
              ? '${product.title} — Pro subscription'
              : product.title),
          subtitle: Text(
              CreditProducts.isSubscription(product.id)
                  ? 'Subscription entitlement; Pro access is verified separately'
                  : '${CreditProducts.amounts[product.id] ?? 0} credits'),
          trailing: FilledButton(
            onPressed: billingService.loading ? null : () => billingService.buy(product),
            child: Text(product.price),
          ),
        ),
      );
}

// These legacy routes are kept until their dedicated screens are split out.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('History')));
}
