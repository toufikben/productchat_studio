import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'services/billing_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';
import 'services/quick_actions_service.dart';
import 'services/rating_prompt_service.dart';
import 'services/remote_config_service.dart';
import 'services/shortcut_handler_service.dart';
import 'services/storage_service.dart';

/// Entry point.
///
/// Every init step is wrapped in its own try/catch so that a failure in one
/// optional service (Hive, RemoteConfig, QuickActions …) never prevents the
/// app from starting. Only [storageService.init] and [runApp] are truly
/// required; everything else degrades gracefully.
Future<void> main() async {
  // Wrap the entire startup in runZonedGuarded so that asynchronous errors
  // thrown outside of Flutter's error handler (e.g. during init) are caught
  // and logged instead of silently killing the process.
  await runZonedGuarded(_boot, (error, stack) {
    // At this point CrashReportingService may not be initialised yet, so
    // print to the console as a last resort.
    debugPrint('[main] uncaught error: $error\n$stack');
    _runFallbackApp();
  });
}

bool _appStarted = false;

Future<void> _boot() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Hive ──────────────────────────────────────────────────────────────
  // Init Hive before anything else; several services depend on it.
  // Each openBox call is wrapped individually so one corrupted box does not
  // block the others.
  try {
    await Hive.initFlutter();
  } catch (e, s) {
    debugPrint('[main] Hive.initFlutter failed: $e\n$s');
  }

  const hiveBoxNames = [
    'settings',
    'history',
    'credits',
    'analytics',
    'voice_presets',
    'presets',
    'favorites',
    'feedback',
    'payments',
    'promos',
    'tickets',
    'drafts',
    'watermark_presets',
    'export_presets',
    'crash_reports',
    'rate_limits',
  ];
  for (final name in hiveBoxNames) {
    await _openHiveBoxSafely(name);
  }

  // ── 2. Crash reporting ───────────────────────────────────────────────────
  // Init as early as possible so subsequent failures are captured.
  try {
    await CrashReportingService.init();
  } catch (e, s) {
    debugPrint('[main] CrashReportingService.init failed: $e\n$s');
  }

  // ── 3. Core storage (SharedPreferences) ─────────────────────────────────
  try {
    await storageService.init();
  } catch (e, s) {
    debugPrint('[main] storageService.init failed: $e\n$s');
    // Non-fatal: the service falls back to an in-memory map.
  }

  // ── 4. Locale & Theme ────────────────────────────────────────────────────
  try {
    await localeController.init();
  } catch (e, s) {
    debugPrint('[main] localeController.init failed: $e\n$s');
  }
  try {
    await themeModeController.init();
  } catch (e, s) {
    debugPrint('[main] themeModeController.init failed: $e\n$s');
  }

  // ── 5. Remote config (network – fully optional) ──────────────────────────
  try {
    await RemoteConfigService().initialize();
  } catch (e, s) {
    debugPrint('[main] RemoteConfigService.initialize failed: $e\n$s');
  }

  // ── 6. Rating prompt (records install date) ──────────────────────────────
  try {
    await RatingPromptService.recordInstallDate();
  } catch (e, s) {
    debugPrint('[main] RatingPromptService.recordInstallDate failed: $e\n$s');
  }

  // ── 7. Billing ───────────────────────────────────────────────────────────
  // billingService.init() contacts Google Play; on devices without Play
  // Services (emulators, dev machines) it will throw or time out. We catch
  // the error here so the app still launches — the billing UI will show an
  // "unavailable" state rather than crashing.
  try {
    await billingService.init();
  } catch (e, s) {
    debugPrint('[main] billingService.init failed (non-fatal): $e\n$s');
  }

  // ── 8. Quick actions (App Shortcuts) ────────────────────────────────────
  // This invokes a MethodChannel that may not be registered in debug builds
  // or on iOS simulators. The service already swallows its own errors but we
  // add an outer guard for safety.
  try {
    await QuickActionsService.init(
      onAction: ShortcutHandlerService.handle,
    );
  } catch (e, s) {
    debugPrint('[main] QuickActionsService.init failed: $e\n$s');
  }

  // ── 9. System UI chrome ──────────────────────────────────────────────────
  try {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  } catch (e, s) {
    debugPrint('[main] SystemChrome setup failed: $e\n$s');
  }

  // ── 10. Launch ───────────────────────────────────────────────────────────
  _appStarted = true;
  runApp(const ProviderScope(child: ProductChatApp()));
}

void _runFallbackApp() {
  if (_appStarted) return;
  _appStarted = true;
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: Text('ProductChat Studio'))),
  ));
}

Future<void> _openHiveBoxSafely(String name) async {
  try {
    if (!Hive.isBoxOpen(name)) await Hive.openBox<dynamic>(name);
    return;
  } catch (error, stack) {
    debugPrint('[main] Hive box "$name" unavailable: $error\n$stack');
  }

  // Preserve the original files instead of deleting them. A fresh empty box
  // keeps callers of Hive.box(name) safe while the old data remains available
  // for manual recovery as a timestamped backup.
  try {
    final directory = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (final suffix in <String>['.hive', '.hive.lock']) {
      final source = File('${directory.path}/$name$suffix');
      if (await source.exists()) {
        final backup = File('${directory.path}/$name.corrupt.$stamp$suffix');
        await source.rename(backup.path);
      }
    }
    if (!Hive.isBoxOpen(name)) await Hive.openBox<dynamic>(name);
    debugPrint('[main] Hive box "$name" recovered with preserved backup');
  } catch (error, stack) {
    // Still do not delete or overwrite user data. Callers must use their
    // normal defaults if the platform prevents recovery during this launch.
    debugPrint('[main] Hive box "$name" recovery failed: $error\n$stack');
  }
}
