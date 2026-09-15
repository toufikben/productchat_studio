import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/model_manager.dart';
import '../../widgets/app_widgets.dart';

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});
  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  String _info = 'Loading...';
  bool _verboseLogging = false;
  String _quality = 'balanced';

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _verboseLogging = Hive.box<dynamic>('settings').get('verboseLog', defaultValue: false) as bool;
    _quality = Hive.box<dynamic>('settings').get('quality', defaultValue: 'balanced') as String;
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    final dir = await getApplicationSupportDirectory();
    final models = Directory('${dir.path}/models');
    var count = 0;
    var size = 0;
    if (await models.exists()) {
      await for (final e in models.list()) {
        if (e is File) { count++; size += await e.length(); }
      }
    }
    if (mounted) {
      setState(() {
        _info = '''
App: ${info.appName}
Version: ${info.version} (${info.buildNumber})
Package: ${info.packageName}
Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}
Dart: ${Platform.version.split(' ').first}
App dir: ${dir.path}
Models: $count (${(size / 1024 / 1024).toStringAsFixed(1)} MB)
''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card('System Info', Icons.info_outline, [
            SelectableText(_info, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12,
              height: 1.6, fontFamily: 'monospace',
            )),
          ]),
          _card('Performance', Icons.speed, [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Processing Quality', style: TextStyle(fontSize: 13)),
              trailing: DropdownButton<String>(
                value: _quality,
                dropdownColor: AppColors.surfaceAlt,
                underline: const SizedBox(),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                items: ['fast', 'balanced', 'best'].map((e) =>
                  DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  setState(() => _quality = v!);
                  Hive.box<dynamic>('settings').put('quality', v);
                },
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Verbose Logging', style: TextStyle(fontSize: 13)),
              value: _verboseLogging,
              onChanged: (v) {
                setState(() => _verboseLogging = v);
                Hive.box<dynamic>('settings').put('verboseLog', v);
              },
            ),
          ]),
          _card('Testing Tools', Icons.bug_report, [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add 100 credits'),
              onTap: () {
                final box = Hive.box<dynamic>('credits');
                box.put('balance', (box.get('balance', defaultValue: 0) as int) + 100);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('+100 credits')));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('View Crash Logs'),
              trailing: const Icon(Icons.bug_report, color: AppColors.warning),
              onTap: () => context.push('/crash-logs'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activate Pro (test)'),
              onTap: () {
                Hive.box<dynamic>('settings').put('isPro', true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pro activated')));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deactivate Pro'),
              onTap: () {
                Hive.box<dynamic>('settings').put('isPro', false);
                Hive.box<dynamic>('settings').put('isLifetime', false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pro deactivated')));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Clear all data'),
              trailing: const Icon(Icons.warning_amber, color: AppColors.danger),
              onTap: () async {
                final ok = await showConfirmDialog(context,
                  title: 'Clear all data?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Clear',
                  destructive: true,
                );
                if (ok) {
                  await Hive.box<dynamic>('settings').clear();
                  await Hive.box<dynamic>('history').clear();
                  await Hive.box<dynamic>('credits').clear();
                  await Hive.box<dynamic>('analytics').clear();
                  await ModelManager().clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cleared')));
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 32),
          Text('v${AppConstants.appVersion} (${AppConstants.buildNumber})',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        const Divider(height: 24),
        ...children,
      ],
    ),
  );
}
