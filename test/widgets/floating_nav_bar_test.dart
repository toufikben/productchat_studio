import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/widgets/floating_nav_bar.dart';
import 'package:productchat_studio/core/theme.dart';

void main() {
  group('NavItem', () {
    test('creates correctly', () {
      const item = NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      );
      expect(item.label, 'Home');
    });
  });

  group('FloatingNavBar', () {
    testWidgets('renders 5 items', (tester) async {
      final items = [
        const NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        const NavItem(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chat'),
        const NavItem(icon: Icons.edit_outlined, activeIcon: Icons.edit, label: 'Editor'),
        const NavItem(icon: Icons.layers_outlined, activeIcon: Icons.layers, label: 'Batch'),
        const NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Stack(
              children: [
                FloatingNavBar(
                  currentIndex: 0,
                  onTap: (_) {},
                  items: items,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('calls onTap when item tapped', (tester) async {
      var tappedIndex = -1;
      final items = [
        const NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        const NavItem(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chat'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Stack(
              children: [
                FloatingNavBar(
                  currentIndex: 0,
                  onTap: (i) => tappedIndex = i,
                  items: items,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chat_outlined));
      expect(tappedIndex, 1);
    });
  });
}
