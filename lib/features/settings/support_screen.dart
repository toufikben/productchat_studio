import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text('Before contacting support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Record the app version, Android version, device model, operation, and whether the issue reproduces after selecting a smaller image.'),
            SizedBox(height: 20),
            Text('Privacy note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Do not send product images or purchase tokens in a support request unless you have reviewed the privacy implications.'),
          ],
        ),
      );
}
