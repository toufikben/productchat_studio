import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('FAQ')),
        body: ListView(
          children: const [
            ExpansionTile(
              title: Text('Where are images processed?'),
              children: [Padding(padding: EdgeInsets.all(16), child: Text('Local editing operations run on the device. Images are not uploaded by the local pipeline.'))],
            ),
            ExpansionTile(
              title: Text('What does Free include?'),
              children: [Padding(padding: EdgeInsets.all(16), child: Text('Free includes three PatchMatch background removals per UTC month with a Free watermark.'))],
            ),
            ExpansionTile(
              title: Text('What does Restore purchases do?'),
              children: [Padding(padding: EdgeInsets.all(16), child: Text('Restore asks Google Play to resend eligible subscription or Lifetime purchase events. Consumable Credits are not restored.'))],
            ),
          ],
        ),
      );
}
