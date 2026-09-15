import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_controller.dart';
import 'layer_panel.dart';
import 'text_panel.dart';
import 'export_dialog.dart';
import '../../core/theme.dart';
import '../../services/billing_service.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  const EditorScreen({super.key, this.imagePath});
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          ref.read(editorProvider.notifier).loadImage(widget.imagePath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(editorProvider);
    final c = ref.read(editorProvider.notifier);
    if (s.imagePath == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Editor')),
          body: const Center(child: Text('Upload an image from chat first')));
    }
    final display =
        s.showBefore && s.originalPath != null ? s.originalPath! : s.imagePath!;
    return Scaffold(
        appBar: AppBar(title: const Text('Editor'), actions: [
          IconButton(
              onPressed: s.canUndo ? c.undo : null,
              icon: const Icon(Icons.undo)),
          IconButton(
              onPressed: s.canRedo ? c.redo : null,
              icon: const Icon(Icons.redo)),
          IconButton(onPressed: _export, icon: const Icon(Icons.download))
        ]),
        body: SafeArea(
            child: Column(children: [
          Expanded(
              child: GestureDetector(
                  onLongPress: c.toggleBefore,
                  child: Stack(children: [
                    Center(
                        child: Opacity(
                            opacity: s.showBefore ? .5 : 1,
                            child: Image.file(File(display),
                                fit: BoxFit.contain))),
                    ...s.texts.asMap().entries.map((e) => Positioned(
                        left: e.value.position.dx,
                        top: e.value.position.dy,
                        child: GestureDetector(
                            onPanUpdate: (d) => c.moveText(e.key, d.delta),
                            onTap: () => c.selectText(e.key),
                            child: Text(e.value.text,
                                style: TextStyle(
                                    color: e.value.color,
                                    fontSize: e.value.fontSize,
                                    fontWeight: e.value.bold
                                        ? FontWeight.bold
                                        : FontWeight.normal))))),
                    if (s.busy)
                      const ColoredBox(
                          color: Colors.black54,
                          child: Center(child: CircularProgressIndicator()))
                  ]))),
          _tools(c),
          if (s.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                s.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (s.showLayers) const LayerPanel(),
          if (s.selectedTextIndex != null) const TextPanel(),
          Padding(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: c.reset, child: const Text('Reset'))),
                const SizedBox(width: 10),
                Expanded(
                    child: FilledButton(
                        onPressed: () => Navigator.pop(context, s.imagePath),
                        child: const Text('Done')))
              ]))
        ])));
  }

  Widget _tools(EditorController c) {
    final isPro = billingService.proService.isPro;
    return Container(
        height: 64,
        color: AppColors.surface,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _tool('BG', c.removeBg),
          _tool('Shadow${isPro ? '' : ' (Pro)'}', c.addShadow),
          _tool('Enhance${isPro ? '' : ' (Pro)'}', c.enhance),
          _tool('Text', c.addText),
          _tool('Layers', c.toggleLayers),
          _tool('Relight${isPro ? '' : ' (Pro)'}', c.relight)
        ]));
  }

  Widget _tool(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.all(8),
      child: OutlinedButton(onPressed: onTap, child: Text(label)));
  Future<void> _export() async {
    final options = await showModalBottomSheet<ExportOptions>(
        context: context, builder: (_) => const ExportDialog());
    if (mounted && options != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Export requested: ${options.format} ${options.size}px')));
    }
  }
}
