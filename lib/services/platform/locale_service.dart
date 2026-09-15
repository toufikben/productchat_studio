import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage_service.dart';

class LocaleController extends ChangeNotifier {
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
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    if (!supportedLanguageCodes.contains(value.languageCode)) return;
    locale = value;
    await storageService.set('locale', value.languageCode);
    notifyListeners();
  }

  bool get isRtl => locale.languageCode == 'ar';
}

final localeController = LocaleController();
final localeProvider = ChangeNotifierProvider<LocaleController>(
  (ref) => localeController,
);
