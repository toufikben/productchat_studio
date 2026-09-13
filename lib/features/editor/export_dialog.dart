import 'package:flutter/material.dart';

class ExportOptions {
  final String format;
  final int size;
  final double quality;
  const ExportOptions(
      {this.format = 'jpg', this.size = 2000, this.quality = .92});
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});
  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String format = 'jpg';
  int size = 2000;
  double quality = .92;
  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Export',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
                value: format,
                items: ['jpg', 'png', 'webp']
                    .map((v) => DropdownMenuItem(
                        value: v, child: Text(v.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => format = v ?? format)),
            DropdownButton<int>(
                value: size,
                items: [1000, 2000, 4000]
                    .map(
                        (v) => DropdownMenuItem(value: v, child: Text('$v px')))
                    .toList(),
                onChanged: (v) => setState(() => size = v ?? size)),
            Slider(
                value: quality,
                min: .5,
                max: 1,
                onChanged: (v) => setState(() => quality = v)),
            FilledButton(
                onPressed: () => Navigator.pop(
                    context,
                    ExportOptions(
                        format: format, size: size, quality: quality)),
                child: const Text('Export'))
          ])));
}
