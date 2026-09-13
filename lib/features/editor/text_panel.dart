import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_controller.dart';

class TextPanel extends ConsumerWidget {
  const TextPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(editorProvider);
    final i = s.selectedTextIndex;
    if (i == null || i >= s.texts.length) return const SizedBox.shrink();
    final text = s.texts[i];
    final controller = TextEditingController(text: text.text);
    return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
              child: TextField(
                  controller: controller,
                  onSubmitted: (v) =>
                      ref.read(editorProvider.notifier).updateText(i, v),
                  decoration: const InputDecoration(labelText: 'Text'))),
          IconButton(
              onPressed: () =>
                  ref.read(editorProvider.notifier).updateText(i, text.text),
              icon: const Icon(Icons.check))
        ]));
  }
}
