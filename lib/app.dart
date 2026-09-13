import 'package:flutter/material.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';

class ProductChatApp extends StatelessWidget {
  const ProductChatApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'ProductChat Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: themeModeProvider.mode,
        locale: localeProvider.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: routerProvider,
      );
}
