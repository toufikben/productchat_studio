import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'services/billing_service.dart';
import 'services/crash_reporting_service.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';
import 'services/quick_actions_service.dart';
import 'services/rating_prompt_service.dart';
import 'services/shortcut_handler_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  for (final name in [
    'settings', 'history', 'credits', 'analytics', 'voice_presets', 'presets',
    'favorites', 'feedback', 'payments', 'promos', 'tickets', 'drafts',
    'watermark_presets', 'export_presets', 'crash_reports',
  ]) {
    if (!Hive.isBoxOpen(name)) await Hive.openBox(name);
  }
  await CrashReportingService.init();
  await RatingPromptService.recordInstallDate();
  await storageService.init();
  await localeController.init();
  await themeModeController.init();
  await billingService.init();

  await QuickActionsService.init(onAction: ShortcutHandlerService.handle);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ProviderScope(child: ProductChatApp()));
}
