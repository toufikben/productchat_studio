import 'package:flutter/material.dart';
import 'package:store_redirect/store_redirect.dart';
import '../core/theme.dart';
import '../services/rating_prompt_service.dart';
import 'app_widgets.dart';

class RatingPromptDialog extends StatelessWidget {
  const RatingPromptDialog({super.key});

  static Future<void> showIfNeeded(BuildContext context) async {
    if (!RatingPromptService.shouldPrompt()) return;

    await showDialog(
      context: context,
      builder: (_) => const RatingPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcons.circle(Icons.star, size: 72),
          const SizedBox(height: 16),
          Text('Enjoying ProductChat?',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'Your rating helps us improve and reach more sellers.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () async {
                    final success = await RatingPromptService.requestReview();
                    if (success) {
                      await RatingPromptService.markRated();
                    } else {
                      await StoreRedirect.redirect(
                        androidAppId: 'com.productchat.studio',
                        iOSAppId: 'com.productchat.studio',
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Rate Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
