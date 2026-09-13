import 'package:flutter/material.dart';

import '../storage_service.dart';

class LocaleController {
  Locale locale = const Locale('en');

  Future<void> init() async {
    final saved = storageService.getString('locale');
    if (saved == 'ar' || saved == 'en') locale = Locale(saved!);
  }

  Future<void> setLocale(Locale value) async {
    if (value.languageCode != 'ar' && value.languageCode != 'en') return;
    locale = value;
    await storageService.set('locale', value.languageCode);
  }

  bool get isRtl => locale.languageCode == 'ar';
}

final localeProvider = LocaleController();
