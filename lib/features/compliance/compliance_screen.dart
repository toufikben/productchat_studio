import 'package:flutter/material.dart';

class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Review checklist')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text('Review before commercial use', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            CheckboxListTile(value: false, onChanged: null, title: Text('Confirm you own or may edit the source image.')),
            CheckboxListTile(value: false, onChanged: null, title: Text('Review edges, text, logos, and generated shadows.')),
            CheckboxListTile(value: false, onChanged: null, title: Text('Confirm the selected model and output are permitted for your use.')),
            SizedBox(height: 12),
            Text('This checklist is guidance, not legal advice. The app does not certify rights, licenses, or regulatory compliance.'),
          ],
        ),
      );
}
