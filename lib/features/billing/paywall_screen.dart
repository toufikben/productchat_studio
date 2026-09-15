import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants.dart';
import '../../services/billing_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({
    super.key,
    this.billing,
    this.initializeBilling = true,
  });

  final BillingService? billing;
  final bool initializeBilling;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  BillingService get _billing => widget.billing ?? billingService;

  @override
  void initState() {
    super.initState();
    if (widget.initializeBilling) _billing.init();
    _billing.addListener(_refresh);
  }

  @override
  void dispose() {
    _billing.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Unlock ProductChat Studio')),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _billing.retry,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              children: [
                if (_billing.loading && !_billing.available)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bolt),
                    title: const Text('Available credits'),
                    trailing: Text(
                      '${_billing.credits}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (!_billing.proService.isPro) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.photo_outlined),
                      title: const Text('Free monthly images'),
                      subtitle: const Text(
                        'PatchMatch-only tier with watermark',
                      ),
                      trailing: Text(
                        '${_billing.freeQuota.remaining}/${AppConstants.freeMonthlyQuota}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const _SectionTitle('Lifetime'),
                _productSection(CreditProducts.lifetime),
                const SizedBox(height: 12),
                const _SectionTitle('Subscriptions'),
                _productSection(CreditProducts.monthly),
                _productSection(CreditProducts.yearly),
                const SizedBox(height: 12),
                const _SectionTitle('Credits'),
                _productSection(CreditProducts.starter),
                _productSection(CreditProducts.standard),
                _productSection(CreditProducts.largePack),
                if (!_billing.available && _billing.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _billing.error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (_billing.loading) const LinearProgressIndicator(),
                if (_billing.available && _billing.products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child:
                        Text('Products are not configured in Google Play yet.'),
                  ),
                if (!_billing.available && !_billing.loading)
                  OutlinedButton.icon(
                    onPressed: _billing.retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Google Play connection'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed:
                      _billing.available ? _billing.restorePurchases : null,
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore purchases'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Google Play prices are shown when available. Credits are not added for pending, failed, or restored consumable purchases. Pro access requires verified entitlement.',
                ),
              ],
            ),
          ),
        ),
      );

  Widget _productSection(String productId) {
    final matches = _billing.products.where((p) => p.id == productId);
    if (matches.isEmpty) return const SizedBox.shrink();
    return _productTile(matches.first);
  }

  Widget _productTile(ProductDetails product) => Card(
        child: ListTile(
          title: Text(_titleFor(product)),
          subtitle: Text(_subtitleFor(product)),
          trailing: FilledButton(
            onPressed: _billing.loading ? null : () => _billing.buy(product),
            child: Text(product.price),
          ),
        ),
      );

  String _titleFor(ProductDetails product) {
    if (product.id == CreditProducts.lifetime) return 'Lifetime Pro';
    if (CreditProducts.isSubscription(product.id)) {
      return '${product.title} — Pro subscription';
    }
    return product.title;
  }

  String _subtitleFor(ProductDetails product) {
    if (product.id == CreditProducts.lifetime) {
      return 'All available Pro features forever';
    }
    if (CreditProducts.isSubscription(product.id)) {
      return 'Pro entitlement; verified separately';
    }
    return '${CreditProducts.amounts[product.id] ?? 0} credits';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}
