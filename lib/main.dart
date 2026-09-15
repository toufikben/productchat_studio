import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/billing_service.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';
import 'services/rating_prompt_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  for (final name in [
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
  ]) {
    if (!Hive.isBoxOpen(name)) await Hive.openBox(name);
  }
  await RatingPromptService.recordInstallDate();
  await storageService.init();
  await localeController.init();
  await themeModeController.init();
  await billingService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(const ProviderScope(child: ProductChatApp()));
}

Future<void> _initializeLocalServices() async {
  try {
    await storageService.init();
    await localeController.init();
    await themeModeController.init();
  } catch (error, stackTrace) {
    debugPrint('Optional local service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
