import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/voice_service.dart';
import '../../widgets/app_widgets.dart';

class VoiceSettingsScreen extends ConsumerStatefulWidget {
  const VoiceSettingsScreen({super.key});
  @override
  ConsumerState<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends ConsumerState<VoiceSettingsScreen> {
  final _testCtrl = TextEditingController(text: 'Hello, this is a test');

  static const _languages = [
    {'code': 'ar-SA', 'name': 'العربية'},
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
    {'code': 'fr-FR', 'name': 'Français'},
    {'code': 'es-ES', 'name': 'Español'},
    {'code': 'de-DE', 'name': 'Deutsch'},
    {'code': 'it-IT', 'name': 'Italiano'},
    {'code': 'pt-BR', 'name': 'Português'},
    {'code': 'ru-RU', 'name': 'Русский'},
    {'code': 'tr-TR', 'name': 'Türkçe'},
    {'code': 'zh-CN', 'name': '中文'},
    {'code': 'ja-JP', 'name': '日本語'},
    {'code': 'ko-KR', 'name': '한국어'},
    {'code': 'hi-IN', 'name': 'हिन्दी'},
    {'code': 'id-ID', 'name': 'Bahasa Indonesia'},
    {'code': 'fa-IR', 'name': 'فارسی'},
    {'code': 'ur-PK', 'name': 'اردو'},
  ];

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    final settings = voice.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Toggles ───
          _section('Features'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up, color: AppColors.primary),
            title: const Text('Voice Feedback'),
            subtitle: const Text('Confirm operations with voice'),
            value: settings.voiceFeedback,
            onChanged: (v) => ref.read(voiceProvider.notifier).toggleVoiceFeedback(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over, color: AppColors.primary),
            title: const Text('Auto-speak results'),
            subtitle: const Text('Read results out loud'),
            value: settings.autoSpeak,
            onChanged: (v) => ref.read(voiceProvider.notifier).toggleAutoSpeak(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.hearing, color: AppColors.primary),
            title: const Text('Wake word'),
            subtitle: const Text('Coming soon'),
            value: settings.wakeWordEnabled,
            onChanged: null, // disabled
          ),

          // ─── Language ───
          _section('Language'),
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.primary),
            title: const Text('Voice Language'),
            subtitle: Text(
              _languages.firstWhere(
                (l) => l['code'] == settings.language,
                orElse: () => {'name': settings.language},
              )['name']!,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, ref, settings.language),
          ),

          // ─── Speech Rate ───
          _section('Speech'),
          ListTile(
            leading: const Icon(Icons.speed, color: AppColors.primary),
            title: const Text('Speech Rate'),
            subtitle: Slider(
              value: settings.speechRate,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: settings.speechRate.toStringAsFixed(1),
              onChanged: (v) => ref.read(voiceProvider.notifier).setSpeechRate(v),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: AppColors.primary),
            title: const Text('Pitch'),
            subtitle: Slider(
              value: settings.pitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: settings.pitch.toStringAsFixed(1),
              onChanged: (v) => ref.read(voiceProvider.notifier).setPitch(v),
            ),
          ),

          // ─── Test ───
          _section('Test'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _testCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Test text',
                    hintText: 'Type something to speak',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ref.read(voiceProvider.notifier).speak(_testCtrl.text),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Speak'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ref.read(voiceProvider.notifier).stopSpeaking(),
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Available voices ───
          _section('Available Voices'),
          FutureBuilder<List<String>>(
            future: ref.read(voiceProvider.notifier).getAvailableLanguages(),
            builder: (context, snap) {
              final langs = snap.data ?? [];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: langs.take(20).map((l) => Chip(
                    label: Text(l, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppColors.surfaceAlt,
                  )).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title.toUpperCase(), style: const TextStyle(
      color: AppColors.textTertiary, fontSize: 11,
      letterSpacing: 0.8, fontWeight: FontWeight.w600)),
  );

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref, String current) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, sc) => ListView.builder(
          controller: sc,
          itemCount: _languages.length,
          itemBuilder: (_, i) {
            final l = _languages[i];
            final isSel = l['code'] == current;
            return ListTile(
              title: Text(l['name']!),
              subtitle: Text(l['code']!),
              trailing: isSel ? const Icon(Icons.check, color: AppColors.success) : null,
              onTap: () => Navigator.pop(context, l['code']),
            );
          },
        ),
      ),
    );
    if (selected != null) {
      await ref.read(voiceProvider.notifier).setLanguage(selected);
    }
  }
}
