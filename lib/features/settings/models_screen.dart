import 'package:flutter/material.dart';

class ModelsScreen extends StatelessWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Models and capabilities')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(leading: Icon(Icons.auto_fix_high), title: Text('PatchMatch'), subtitle: Text('Local background removal. Available to Free with watermark.')),
            ListTile(leading: Icon(Icons.photo_size_select_large), title: Text('Basic enhancement'), subtitle: Text('Local bounded fallback; not advertised as Real-ESRGAN.')),
            ListTile(leading: Icon(Icons.blur_on), title: Text('LaMa'), subtitle: Text('Android runtime requires device validation before release claims.')),
            ListTile(leading: Icon(Icons.block), title: Text('MI-GAN'), subtitle: Text('Disabled until commercial redistribution permission is established.')),
          ],
        ),
      );
}
