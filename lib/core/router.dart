import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/chat_screen.dart';
import '../features/splash/splash_screen.dart';
final routerProvider = GoRouter(initialLocation: '/splash', routes: [GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()), GoRoute(path: '/chat', builder: (_, __) => const ChatScreen())], errorBuilder: (_, __) => const Scaffold(body: Center(child: Text('Page not found'))));
