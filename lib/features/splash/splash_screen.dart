import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await NotificationService.init();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.bg, Color(0xFF12182B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryGlow],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      size: 50, color: Colors.white),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
                const SizedBox(height: 24),
                Text('ProductChat Studio',
                        style: Theme.of(c).textTheme.displayLarge)
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 8),
                Text('Conversational AI for Product Photos',
                        style: Theme.of(c).textTheme.bodyMedium)
                    .animate()
                    .fadeIn(delay: 500.ms),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      );
}
