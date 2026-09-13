import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class SplashScreen extends StatelessWidget { const SplashScreen({super.key}); @override Widget build(BuildContext c) { Future.delayed(const Duration(milliseconds: 1800), () { if (c.mounted) c.go('/chat'); }); return const Scaffold(body: Center(child: Text('ProductChat Studio'))); } }
