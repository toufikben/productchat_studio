import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacy and Terms')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            Text('Privacy Policy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('ProductChat Studio processes selected product images locally on the device when using local AI features. Images are not uploaded by the local editing pipeline. Model downloads use the configured model repository.'),
            SizedBox(height: 24),
            Text('Terms of Use', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('You are responsible for the images you edit and export. AI results are provided as editing assistance and should be reviewed before commercial use. Billing and store terms will apply when purchases are enabled.'),
            SizedBox(height: 24),
            Text('Data retention', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Selected images and local AI outputs remain on the device unless you explicitly share or export them. Durable settings and a bounded local History are stored on-device using versioned metadata. Deleting a History item deletes its recorded output when the file is still available; clearing History removes recorded outputs. The operating system may also remove cache files.'),
          ],
        ),
      );
}
