import 'package:flutter/material.dart';

import 'app.dart';
import 'services/storage_service.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await storageService.init();
  await localeProvider.init();
  await themeModeProvider.init();
  runApp(const ProductChatApp());
}
