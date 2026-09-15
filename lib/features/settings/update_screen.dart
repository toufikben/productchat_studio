import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme.dart';
import '../../widgets/app_widgets.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});
  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  String _currentVersion = '';
  bool _checking = false;
  String? _latestVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _currentVersion = info.version);
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    await Future.delayed(const Duration(seconds: 2));
    // In production: fetch from server or store
    // For now: simulate up-to-date
    if (mounted) {
      setState(() {
        _checking = false;
        _latestVersion = _currentVersion;
      });
    }
  }

  bool get _hasUpdate =>
      _latestVersion != null && _latestVersion != _currentVersion;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check for Updates')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            AppIcons.circle(Icons.system_update, size: 100),
            const SizedBox(height: 24),
            Text(
              _checking
                  ? 'Checking for updates...'
                  : _hasUpdate
                      ? 'Update Available!'
                      : 'You are up to date',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _checking
                  ? ''
                  : _hasUpdate
                      ? 'Version $_latestVersion is available. Current: $_currentVersion'
                      : 'Current version: $_currentVersion',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_checking)
              const CircularProgressIndicator(color: AppColors.primary)
            else if (_hasUpdate)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final url = Uri.parse('market://details?id=com.productchat.studio');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Update Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _checkForUpdates,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
