import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class OnboardingTip {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final String? route;

  const OnboardingTip({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    this.route,
  });
}

const kOnboardingTips = <OnboardingTip>[
  OnboardingTip(
    id: 'chat_studio',
    title: 'Chat with your image',
    body: 'Just type "remove background" or "add shadow" — the AI does the rest.',
    icon: Icons.chat_bubble_outline,
    route: '/chat-studio',
  ),
  OnboardingTip(
    id: 'smart_analysis',
    title: 'Let AI suggest improvements',
    body: 'Upload an image and we analyze it automatically with 5 suggestions.',
    icon: Icons.auto_awesome,
  ),
  OnboardingTip(
    id: 'voice_commands',
    title: 'Use voice commands',
    body: 'Tap the mic and speak your command in 17 languages.',
    icon: Icons.mic,
    route: '/voice-settings',
  ),
  OnboardingTip(
    id: 'batch_processing',
    title: 'Process 100 images at once',
    body: 'Pro users can batch process with automatic background removal.',
    icon: Icons.layers,
    route: '/batch',
  ),
  OnboardingTip(
    id: 'brand_identity',
    title: 'Save your brand',
    body: 'Apply your logo, colors, and fonts to every export.',
    icon: Icons.business,
    route: '/brand',
  ),
  OnboardingTip(
    id: 'compliance',
    title: 'Check marketplace compliance',
    body: 'Verify your images meet Amazon, Etsy, and Shopify requirements.',
    icon: Icons.verified_outlined,
    route: '/compliance',
  ),
  OnboardingTip(
    id: 'models',
    title: 'Download AI models',
    body: 'Get LaMa and Real-ESRGAN for advanced editing.',
    icon: Icons.download,
    route: '/models',
  ),
  OnboardingTip(
    id: 'privacy',
    title: 'Your photos stay private',
    body: 'All processing happens on your device. Nothing is uploaded.',
    icon: Icons.security,
  ),
];

class OnboardingTipsScreen extends StatefulWidget {
  const OnboardingTipsScreen({super.key});
  @override
  State<OnboardingTipsScreen> createState() => _OnboardingTipsScreenState();
}

class _OnboardingTipsScreenState extends State<OnboardingTipsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tips & Tricks'),
        actions: [
          TextButton(
            onPressed: _markAllSeen,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                kOnboardingTips.length,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentIndex
                          ? AppColors.primary
                          : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: kOnboardingTips.length,
              itemBuilder: (_, i) => _TipPage(tip: kOnboardingTips[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentIndex--),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _currentIndex == kOnboardingTips.length - 1
                      ? _markAllSeen
                      : () => setState(() => _currentIndex++),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: Text(
                    _currentIndex == kOnboardingTips.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllSeen() async {
    await Hive.box<dynamic>('settings').put('tips_seen', true);
    if (mounted) Navigator.pop(context);
  }
}

class _TipPage extends StatelessWidget {
  final OnboardingTip tip;
  const _TipPage({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcons.circle(tip.icon, size: 120),
          const SizedBox(height: 32),
          Text(tip.title,
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(tip.body,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Utility to check if tips should be shown.
bool shouldShowTips() {
  return !(Hive.box<dynamic>('settings').get('tips_seen', defaultValue: false) as bool);
}
