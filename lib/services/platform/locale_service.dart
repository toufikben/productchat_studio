import 'package:flutter/material.dart';

import '../storage_service.dart';

class LocaleController {
  static const supportedLanguageCodes = <String>{
    'ar',
    'en',
    'fr',
    'es',
    'de',
    'it',
    'pt',
    'ru',
    'tr',
    'zh',
    'ja',
    'ko',
    'hi',
    'id',
    'fa',
    'ur',
  };

  Locale locale = const Locale('en');

  Future<void> init() async {
    final saved = storageService.getString('locale');
    if (saved != null && supportedLanguageCodes.contains(saved)) {
      locale = Locale(saved);
    }
  }

  Future<void> setLocale(Locale value) async {
    if (!supportedLanguageCodes.contains(value.languageCode)) return;
    locale = value;
    await storageService.set('locale', value.languageCode);
  }

  bool get isRtl => locale.languageCode == 'ar';
}

final localeProvider = LocaleController();
