import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/promo_code_service.dart';
import '../../widgets/app_widgets.dart';

final promoServiceProvider = Provider((_) => PromoCodeService());

class PromoCodeScreen extends ConsumerStatefulWidget {
  const PromoCodeScreen({super.key});
  @override
  ConsumerState<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends ConsumerState<PromoCodeScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  PromoResult? _result;

  Future<void> _redeem() async {
    if (_ctrl.text.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });

    final result = await ref.read(promoServiceProvider).redeem(_ctrl.text);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = result;
    });

    if (result.ok) {
      _ctrl.clear();
      showSuccessSnack(context, result.message);
    } else {
      showErrorSnack(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promo Code')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppIcons.circle(Icons.card_giftcard, size: 100),
          const SizedBox(height: 24),
          Text('Have a promo code?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Enter it below to unlock rewards',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
            decoration: const InputDecoration(
              hintText: 'ABCD1234',
              hintStyle: TextStyle(
                fontSize: 24,
                letterSpacing: 4,
                fontFamily: 'monospace',
                color: AppColors.textTertiary,
              ),
            ),
            onSubmitted: (_) => _redeem(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _redeem,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: const Text('Redeem'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Example codes:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          _exampleCode('WELCOME10', '+10 credits'),
          _exampleCode('LAUNCH50', '+50 credits'),
          _exampleCode('PRO7DAY', '7 days Pro'),
        ],
      ),
    );
  }

  Widget _exampleCode(String code, String reward) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Text(code, style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        )),
        const Spacer(),
        Text(reward, style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        )),
      ],
    ),
  );
}
