import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Recipes')),
        body: ListView(
          children: const [
            ListTile(leading: Icon(Icons.crop_free), title: Text('Clean background'), subtitle: Text('Run local PatchMatch background removal, then review the transparent output.')),
            ListTile(leading: Icon(Icons.wb_sunny_outlined), title: Text('Product shadow'), subtitle: Text('Use the Shadow operation for a grounded product presentation. Pro/Lifetime required.')),
            ListTile(leading: Icon(Icons.photo_size_select_large), title: Text('Prepare for export'), subtitle: Text('Choose output format and size after reviewing the edit.')),
          ],
        ),
      );
}
