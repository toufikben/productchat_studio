import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/features/batch/batch_screen.dart';
import 'package:productchat_studio/features/billing/paywall_screen.dart';
import 'package:productchat_studio/features/history/history_screen.dart';
import 'package:productchat_studio/features/settings/settings_screen.dart';
import 'package:productchat_studio/services/billing_service.dart';
import 'package:productchat_studio/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
