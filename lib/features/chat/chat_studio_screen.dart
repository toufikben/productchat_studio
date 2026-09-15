import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/voice_service.dart';

class ChatStudioScreen extends ConsumerStatefulWidget {
  const ChatStudioScreen({super.key});
  @override
  ConsumerState<ChatStudioScreen> createState() => _ChatStudioScreenState();
}

class _ChatStudioScreenState extends ConsumerState<ChatStudioScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({String text, bool isUser})>[(text: 'مرحباً! ارفع صورة منتجك واكتب أمرك.', isUser: false)];

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() { _messages.add((text: text, isUser: true)); _ctrl.clear(); });
    WidgetsBinding.instance.addPostFrameCallback((_) { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut); });
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    return SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.all(20), child: Row(children: [Expanded(child: Text('Chat Studio', style: Theme.of(context).textTheme.displayLarge)), if (voice.isSpeaking) IconButton(icon: const Icon(Icons.volume_off, color: AppColors.danger), onPressed: () => ref.read(voiceProvider.notifier).stopSpeaking())])),
      Expanded(child: ListView(controller: _scroll, padding: const EdgeInsets.symmetric(horizontal: 20), children: _messages.map((m) => _ChatBubble(text: m.text, isUser: m.isUser)).toList())),
      if (voice.isListening) Padding(padding: const EdgeInsets.all(20), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(20, (i) => AnimatedContainer(duration: Duration(milliseconds: 100 + i * 30), margin: const EdgeInsets.symmetric(horizontal: 2), width: 4, height: 10 + (i % 5) * 8.0, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))))),
      Container(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), child: Row(children: [IconButton(icon: const Icon(Icons.add_photo_alternate_outlined), onPressed: () {}, color: AppColors.primary), Expanded(child: Container(decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)), child: TextField(controller: _ctrl, onSubmitted: (_) => _send(), decoration: const InputDecoration(hintText: 'اكتب أمرك...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send), color: AppColors.primary, onPressed: _send), GestureDetector(onTap: () { final service = ref.read(voiceProvider.notifier); voice.isListening ? service.stopListening() : service.startListening(); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 48, height: 48, decoration: BoxDecoration(color: voice.isListening ? AppColors.danger : AppColors.primary, shape: BoxShape.circle), child: Icon(voice.isListening ? Icons.stop : Icons.mic, color: Colors.white)))])),
    ]));
  }
}

class _ChatBubble extends StatelessWidget { final String text; final bool isUser; const _ChatBubble({required this.text, required this.isUser}); @override Widget build(BuildContext context) => Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .75), decoration: BoxDecoration(color: isUser ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(18), border: isUser ? null : Border.all(color: AppColors.border)), child: Text(text, style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary)))); }
