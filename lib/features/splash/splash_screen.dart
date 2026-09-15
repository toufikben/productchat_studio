import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash screen that navigates to /chat after a fixed delay.
///
/// Uses [StatefulWidget] with [initState] so the timer fires exactly once,
/// even if the widget is rebuilt (e.g. theme or locale change) during the
/// 1 800 ms window. The old [StatelessWidget] version re-fired [Future.delayed]
on every rebuild, which could produce multiple navigations.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/chat');
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('ProductChat Studio')));
}
