import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/chat_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/batch/batch_screen.dart';

final routerProvider = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(
          path: '/editor',
          builder: (_, state) =>
              EditorScreen(imagePath: state.uri.queryParameters['imagePath'])),
      GoRoute(path: '/batch', builder: (_, __) => const BatchScreen())
    ],
    errorBuilder: (_, __) =>
        const Scaffold(body: Center(child: Text('Page not found'))));
