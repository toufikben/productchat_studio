import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/voice_service.dart';

class ChatStudioScreen extends ConsumerStatefulWidget {
  const ChatStudioScreen({super.key});
  @override
  ConsumerState<ChatStudioScreen> createState() => _ChatStudioScreenState();
}

class _ChatStudioScreenState extends ConsumerState<ChatStudioScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Chat Studio'),
        actions: [
          if (voice.isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off, color: AppColors.danger),
              onPressed: () => ref.read(voiceProvider.notifier).stopSpeaking(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                _ChatBubble(
                  text: 'Welcome! Upload an image and type your command.',
                  isUser: false,
                ),
              ],
            ),
          ),
          if (voice.isListening)
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(20, (i) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 100 + (i * 30)),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 10 + (i % 5) * 8.0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: () {},
                  color: AppColors.primary,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Type your command...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (voice.isListening) {
                      ref.read(voiceProvider.notifier).stopListening();
                    } else {
                      ref.read(voiceProvider.notifier).startListening();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: voice.isListening ? AppColors.danger : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (voice.isListening ? AppColors.danger : AppColors.primary)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      voice.isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  const _ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: TextStyle(
              color: isUser ? Colors.white : AppColors.textPrimary,
            )),
      ),
    );
  }
}
