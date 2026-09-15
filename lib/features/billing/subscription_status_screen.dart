import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/pro_service.dart';
import '../../services/billing_service.dart';
import '../../services/trial_service.dart';
import '../../services/free_quota_service.dart';
import '../../services/payment_history_service.dart';
import '../../widgets/app_widgets.dart';

class SubscriptionStatusScreen extends ConsumerWidget {
  const SubscriptionStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pro = billingService.proService;
    final trial = ref.watch(trialProvider);
    final quota = ref.watch(freeQuotaProvider);
    final history = PaymentHistoryService().getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Status Banner ───
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pro.isPro
                    ? [AppColors.success, const Color(0xFF00A075)]
                    : [AppColors.primary, AppColors.primaryGlow],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  pro.isLifetime
                      ? Icons.workspace_premium
                      : pro.isPro
                          ? Icons.star
                          : trial.isActive
                              ? Icons.timer
                              : Icons.person_outline,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  pro.isLifetime
                      ? 'Lifetime Pro'
                      : pro.isPro
                          ? 'Pro Active'
                          : trial.isActive
                              ? 'Free Trial'
                              : 'Free Tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pro.isLifetime
                      ? 'Forever yours ✨'
                      : pro.isPro
                          ? 'Renews in ${pro.daysRemaining} days'
                          : trial.isActive
                              ? '${trial.daysRemaining} days remaining'
                              : '${quota.remaining}/${AppConstants.freeMonthlyQuota} free images this month',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ─── Quota Info ───
          if (!pro.isPro) ...[
            _card('Free Quota', [
              _row('Used', '${quota.used}/${AppConstants.freeMonthlyQuota}'),
              _row('Remaining', '${quota.remaining}'),
              _row('Next reset',
                  '${quota.nextReset.day}/${quota.nextReset.month}/${quota.nextReset.year}'),
            ]),
            const SizedBox(height: 12),
          ],

          // ─── Credits ───
          _card('Credits Balance', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt, color: AppColors.warning),
              title: Text(
                '${Hive.box<dynamic>('credits').get('balance', defaultValue: 0)} credits',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              trailing: TextButton(
                onPressed: () => context.push('/paywall'),
                child: const Text('Buy More'),
              ),
            ),
          ]),

          const SizedBox(height: 12),

          // ─── Actions ───
          if (!pro.isPro)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/paywall'),
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Upgrade to Pro'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ─── Payment History ───
          const Text('Payment History',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('No payments yet',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            ...history.take(10).map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    r.status == 'refunded'
                        ? Icons.replay
                        : Icons.check_circle,
                    color: r.status == 'refunded'
                        ? AppColors.warning
                        : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.productName,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${r.date.day}/${r.date.month}/${r.date.year}',
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('\$${r.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            )),

          const SizedBox(height: 24),

          // ─── Actions ───
          _card('Manage', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore, color: AppColors.primary),
              title: const Text('Restore Purchases'),
              onTap: () async {
                // Trigger restore
                showSuccessSnack(context, 'Restore initiated');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('Refund Policy'),
              onTap: () => context.push('/refund-policy'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              title: const Text('Cancel Subscription'),
              onTap: () => _showCancelDialog(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel Subscription?'),
        content: const Text(
          'To cancel, you need to go through your app store settings:\n\n'
          '• Google Play: Subscriptions\n'
          '• App Store: Subscriptions',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
