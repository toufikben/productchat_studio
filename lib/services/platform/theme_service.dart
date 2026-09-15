import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage_service.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.dark;

  Future<void> init() async {
    final saved = storageService.getString('themeMode');
    if (saved == 'light') mode = ThemeMode.light;
    if (saved == 'dark') mode = ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    await storageService.set(
      'themeMode',
      value == ThemeMode.light ? 'light' : 'dark',
    );
    notifyListeners();
  }
}

final themeModeController = ThemeModeController();
final themeModeProvider = ChangeNotifierProvider<ThemeModeController>(
  (ref) => themeModeController,
);
