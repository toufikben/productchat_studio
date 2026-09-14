import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class SplashScreen extends StatelessWidget { const SplashScreen({super.key}); @override Widget build(BuildContext context) { Future.delayed(const Duration(milliseconds: 1800), () { if (context.mounted) context.go('/chat'); }); return const Scaffold(body: Center(child: Text('ProductChat Studio'))); } }
