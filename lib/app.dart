import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';
import 'services/shortcut_handler_service.dart';
import 'widgets/error_boundary.dart';

class ProductChatApp extends ConsumerStatefulWidget {
  const ProductChatApp({super.key});
  @override
  ConsumerState<ProductChatApp> createState() => _ProductChatAppState();
}

class _ProductChatAppState extends ConsumerState<ProductChatApp> {
  @override
  void initState() {
    super.initState();
    ShortcutHandlerService.init(_handleShortcut);
  }

  void _handleShortcut(String type) {
    final router = ref.read(routerProvider);
    switch (type) {
      case 'new_edit':
      case 'scan': router.go('/chat');
      case 'batch': router.go('/batch');
      case 'history': router.go('/timeline');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return ErrorBoundary(
      child: MaterialApp.router(
        title: 'ProductChat Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode.mode,
        locale: locale.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
