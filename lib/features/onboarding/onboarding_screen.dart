import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Getting started')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.auto_awesome, size: 72),
            const SizedBox(height: 20),
            Text('Create better product photos locally', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Choose an image, try PatchMatch background removal, and review every result before export. Local operations do not upload your images.'),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => context.go('/home'), child: const Text('Start editing')),
          ],
        ),
      );
}
