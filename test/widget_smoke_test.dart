import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:productchat_studio/features/batch/batch_screen.dart';
import 'package:productchat_studio/features/billing/paywall_screen.dart';
import 'package:productchat_studio/features/history/history_screen.dart';
import 'package:productchat_studio/features/settings/settings_screen.dart';
import 'package:productchat_studio/app.dart';
import 'package:productchat_studio/core/router.dart';
import 'package:productchat_studio/services/billing_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final directory = await Directory.systemTemp.createTemp('productchat-widget-');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('settings');
    await Hive.openBox<dynamic>('payments');
    await Hive.openBox<dynamic>('analytics');
    await Hive.openBox<dynamic>('credits');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('Paywall renders all plan sections without initializing Play Billing',
      (tester) async {
    final billing = BillingService(storage: StorageService());

    await tester.pumpWidget(
      MaterialApp(
        home: PaywallScreen(billing: billing, initializeBilling: false),
      ),
    );
    await tester.pump();

    expect(find.text('Unlock ProductChat Studio'), findsOneWidget);
    expect(find.text('Lifetime'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);

    billing.dispose();
  });

  testWidgets('Settings renders Free status and navigation actions', (tester) async {
    final billing = BillingService(storage: StorageService());

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(billing: billing),
      ),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Free tier'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    expect(find.text('View Pro and Lifetime plans'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Batch processing'), 400);
    expect(find.text('Batch processing'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);

    billing.dispose();
  });

  testWidgets('Batch screen renders the Pro gate for Free users', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: BatchScreen()),
      ),
    );

    expect(find.text('Batch processing'), findsOneWidget);
    expect(find.text('Batch requires Pro or Lifetime'), findsOneWidget);
    expect(find.text('Select images'), findsOneWidget);
  });

  testWidgets('History screen renders its empty state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HistoryScreen()),
    );

    expect(find.text('History'), findsOneWidget);
    expect(find.text('No successful edits yet.'), findsOneWidget);
  });

  testWidgets('Settings restore action reports no entitlement without Play Billing',
      (tester) async {
    final billing = BillingService(storage: StorageService());
    await tester.pumpWidget(
      MaterialApp(home: SettingsScreen(billing: billing)),
    );

    await tester.tap(find.text('Restore purchases'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Free tier'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    billing.dispose();
  });

  testWidgets('Batch action is disabled for Free users', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: BatchScreen())),
    );

    final selectImages = find.text('Select images');
    expect(selectImages, findsOneWidget);
    await tester.tap(selectImages);
    expect(find.text('Choose batch operation'), findsNothing);
  });

  testWidgets('Router navigates to Settings and handles unknown routes',
      (tester) async {
    final container = ProviderContainer();
    final router = container.read(routerProvider);
    router.go('/settings');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    router.go('/route-that-does-not-exist');
    await tester.pumpAndSettle();
    expect(find.text('Page not found'), findsOneWidget);
    container.dispose();
  });
}
