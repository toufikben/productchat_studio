import 'package:flutter/material.dart';

import '../storage_service.dart';

class ThemeModeController {
  ThemeMode mode = ThemeMode.dark;

  Future<void> init() async {
    final saved = storageService.getString('themeMode');
    if (saved == 'light') mode = ThemeMode.light;
    if (saved == 'dark') mode = ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode value) async {
    mode = value;
    await storageService.set(
      'themeMode',
      value == ThemeMode.light ? 'light' : 'dark',
    );
  }
}

final themeModeProvider = ThemeModeController();
