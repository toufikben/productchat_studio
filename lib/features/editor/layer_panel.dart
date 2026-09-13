import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_controller.dart';

class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(editorProvider);
    return SizedBox(
        height: 72,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: s.texts.length + 1,
            itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(8),
                child: Chip(
                    label: Text(i == 0 ? 'Image' : 'Text $i'),
                    onDeleted: i == 0
                        ? null
                        : () => ref
                            .read(editorProvider.notifier)
                            .removeText(i - 1)))));
  }
}
