import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Optional services must not block the first frame. Google Play Billing (and
  // local storage on some devices) can be unavailable or slow during launch.
  runApp(const ProviderScope(child: ProductChatApp()));

  unawaited(_initializeLocalServices());
}

Future<void> _initializeLocalServices() async {
  try {
    await storageService.init();
    await localeController.init();
    await themeModeController.init();
  } catch (error, stackTrace) {
    // Keep the in-memory defaults if storage is unavailable or corrupted.
    debugPrint('Optional local service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
