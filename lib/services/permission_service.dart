import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestInitialPermissions(BuildContext context) async {
    final status = await Permission.photos.status;
    if (status.isGranted || status.isLimited) return;
    if (!context.mounted) return;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Photo access'),
        content: const Text(
          'ProductChat Studio needs access to your photos so you can select a product image for editing. You can change this permission later in Android Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true) return;

    final result = await Permission.photos.request();
    if (!context.mounted || result.isGranted || result.isLimited) return;
    if (result.isPermanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Photo access is disabled'),
          content: const Text(
            'Enable Photos permission in Android Settings to choose product images.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );
    }
  }
}
