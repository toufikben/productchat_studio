import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refund Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Refund Policy',
                style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            const Text('Last updated: September 15, 2026',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            const SizedBox(height: 24),
            _section('1. Overview', '''
We want you to be completely satisfied with ProductChat Studio.
If you are not satisfied, this policy explains your options.'''),
            _section('2. Subscriptions', '''
Subscriptions are managed by Google Play or the App Store.

Refunds for subscriptions:
• Within 48 hours: Contact the app store directly
• After 48 hours: Refunds are at the store's discretion
• Cancellations: You keep Pro until end of billing period'''),
            _section('3. Credits', '''
Credits are consumed on first use.

Refundable:
• Unused credits within 14 days of purchase
• Full refund minus payment processing fees

Not refundable:
• Credits already used for operations
• Credits beyond 14 days of purchase'''),
            _section('4. Lifetime Purchase', '''
Lifetime purchases are refundable within 14 days if unused.

After 14 days, refunds are provided only in cases of:
• Technical failure preventing use
• Accidental duplicate purchase
• Verified unauthorized transaction'''),
            _section('5. Chargeback Policy', '''
If you initiate a chargeback (dispute) with your bank:
• Your Pro access will be suspended immediately
• Your account will be flagged
• Any remaining credits may be forfeited
• Re-purchase will be required to restore access

We encourage contacting us first at support@productchat.app'''),
            _section('6. Free Trial', '''
7-day free trial is available once per user.

Trial:
• Grants full Pro access
• Auto-converts to free tier (no charge) if not subscribed
• Cannot be repeated on the same account'''),
            _section('7. Contact', '''
For refund requests:
Email: refunds@productchat.app
Response time: within 48 hours

Please include:
• Your order ID
• Reason for refund
• Screenshots if applicable'''),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 14, height: 1.7)),
      ],
    ),
  );
}
