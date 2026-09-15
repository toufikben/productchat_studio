import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../widgets/app_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                AppIcons.gradient(Icons.auto_awesome, size: 100, iconSize: 50),
                const SizedBox(height: 16),
                Text('ProductChat Studio',
                  style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 6),
                Text('v${AppConstants.appVersion} (${AppConstants.buildNumber})',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                const Text('Conversational AI for Product Photos',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _tile(context, Icons.language, 'Website',
            'productchat.app', 'https://productchat.app'),
          _tile(context, Icons.email, 'Contact',
            'support@productchat.app', 'mailto:support@productchat.app'),
          _tile(context, Icons.privacy_tip, 'Privacy Policy',
            'View', 'https://productchat.app/privacy'),
          _tile(context, Icons.gavel, 'Terms of Service',
            'View', 'https://productchat.app/terms'),
          _tile(context, Icons.code, 'Open Source',
            'github.com/Toufikben/productchat_studio',
            'https://github.com/Toufikben/productchat_studio'),
          _tile(context, Icons.gavel, 'Model Licenses',
            'MIT, Apache 2.0, BSD-3',
            'https://github.com/toufikben/productchat_studio/blob/main/docs/MODEL_LICENSES.md'),
          const SizedBox(height: 24),
          const Center(
            child: Text('Made with ❤️ by ProductChat Team',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, String url) =>
    Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AppIcons.outline(icon, size: 40),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ),
    );
}
