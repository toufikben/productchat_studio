import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/hive_ext.dart';

class VoiceState {
  final bool isListening;
  final bool isSpeaking;
  final String lastTranscription;
  final String lastError;
  final double soundLevel;
  final String? lastSpoken;
  final VoiceSettings settings;

  const VoiceState({
    this.isListening = false,
    this.isSpeaking = false,
    this.lastTranscription = '',
    this.lastError = '',
    this.soundLevel = 0.0,
    this.lastSpoken,
    this.settings = const VoiceSettings(),
  });

  VoiceState copyWith({
    bool? isListening,
    bool? isSpeaking,
    String? lastTranscription,
    String? lastError,
    double? soundLevel,
    String? lastSpoken,
    VoiceSettings? settings,
  }) =>
      VoiceState(
        isListening: isListening ?? this.isListening,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        lastTranscription: lastTranscription ?? this.lastTranscription,
        lastError: lastError ?? this.lastError,
        soundLevel: soundLevel ?? this.soundLevel,
        lastSpoken: lastSpoken ?? this.lastSpoken,
        settings: settings ?? this.settings,
      );
}

class VoiceSettings {
  final bool voiceFeedback;
  final bool autoSpeak;
  final bool wakeWordEnabled;
  final String language;
  final double speechRate;
  final double pitch;

  const VoiceSettings({
    this.voiceFeedback = true,
    this.autoSpeak = false,
    this.wakeWordEnabled = false,
    this.language = 'ar-SA',
    this.speechRate = 0.5,
    this.pitch = 1.0,
  });

  VoiceSettings copyWith({
    bool? voiceFeedback,
    bool? autoSpeak,
    bool? wakeWordEnabled,
    String? language,
    double? speechRate,
    double? pitch,
  }) =>
      VoiceSettings(
        voiceFeedback: voiceFeedback ?? this.voiceFeedback,
        autoSpeak: autoSpeak ?? this.autoSpeak,
        wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
        language: language ?? this.language,
        speechRate: speechRate ?? this.speechRate,
        pitch: pitch ?? this.pitch,
      );

  Map<String, dynamic> toMap() => {
        'voiceFeedback': voiceFeedback,
        'autoSpeak': autoSpeak,
        'wakeWordEnabled': wakeWordEnabled,
        'language': language,
        'speechRate': speechRate,
        'pitch': pitch,
      };

  factory VoiceSettings.fromMap(Map<String, dynamic> map) => VoiceSettings(
        voiceFeedback: map['voiceFeedback'] as bool? ?? true,
        autoSpeak: map['autoSpeak'] as bool? ?? false,
        wakeWordEnabled: map['wakeWordEnabled'] as bool? ?? false,
        language: map['language'] as String? ?? 'ar-SA',
        speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.5,
        pitch: (map['pitch'] as num?)?.toDouble() ?? 1.0,
      );
}

class VoiceService extends StateNotifier<VoiceState> {
  VoiceService() : super(const VoiceState()) {
    _loadSettings();
  }

  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _sttInitialized = false;
  final _transcriptionController = StreamController<String>.broadcast();

  Stream<String> get onTranscription => _transcriptionController.stream;

  void _loadSettings() {
    if (!Hive.isBoxOpen('settings')) return;
    final box = Hive.box<dynamic>('settings');
    final settings = box.getMap('voice_settings');
    if (settings.isNotEmpty) {
      state = state.copyWith(settings: VoiceSettings.fromMap(settings));
    }
  }

  Future<void> _persistSettings() async {
    await Hive.box<dynamic>('settings')
        .put('voice_settings', state.settings.toMap());
  }

  Future<void> init() async {
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) => state = state.copyWith(lastError: error.errorMsg),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
      );
      await _tts.setLanguage(state.settings.language);
      await _tts.setSpeechRate(state.settings.speechRate);
      await _tts.setPitch(state.settings.pitch);
      await _tts.setVolume(1.0);
      _tts.setCompletionHandler(
          () => state = state.copyWith(isSpeaking: false));
    } catch (error) {
      state = state.copyWith(lastError: error.toString());
    }
  }

  Future<void> startListening({String? localeId}) async {
    if (!_sttInitialized) await init();
    if (!_sttInitialized) {
      state = state.copyWith(lastError: 'Speech recognition not available');
      return;
    }
    state = state.copyWith(isListening: true, lastError: '');
    await _stt.listen(
      onResult: (result) {
        state = state.copyWith(lastTranscription: result.recognizedWords);
        _transcriptionController.add(result.recognizedWords);
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId ?? state.settings.language,
        listenMode: ListenMode.confirmation,
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> speak(String text,
      {String? locale, bool feedback = false}) async {
    if (!state.settings.voiceFeedback && feedback) return;
    await _tts.setLanguage(locale ?? state.settings.language);
    await _tts.setSpeechRate(state.settings.speechRate);
    await _tts.setPitch(state.settings.pitch);
    state = state.copyWith(isSpeaking: true, lastSpoken: text);
    try {
      await _tts.speak(text);
    } catch (error) {
      state = state.copyWith(isSpeaking: false, lastError: error.toString());
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> announceOperation({
    required String operation,
    required bool success,
    String? details,
  }) async {
    if (!state.settings.voiceFeedback) return;
    final message = success
        ? _successMessage(operation, details)
        : _failureMessage(operation);
    await speak(message, feedback: true);
  }

  String _successMessage(String operation, String? details) {
    final isArabic = state.settings.language.startsWith('ar');
    if (isArabic) {
      switch (operation) {
        case 'removeBg':
          return 'تمت إزالة الخلفية بنجاح';
        case 'enhance':
          return 'تم تحسين الصورة';
        case 'shadow':
          return 'تمت إضافة الظل';
        case 'relight':
          return 'تم تعديل الإضاءة';
        case 'colorize':
          return 'تم تلوين الصورة';
        case 'export':
          return 'تم تصدير الصورة';
        default:
          return 'تمت العملية بنجاح';
      }
    }
    switch (operation) {
      case 'removeBg':
        return 'Background removed successfully';
      case 'enhance':
        return 'Image enhanced';
      case 'shadow':
        return 'Shadow added';
      case 'relight':
        return 'Lighting adjusted';
      case 'colorize':
        return 'Image colorized';
      case 'export':
        return 'Image exported';
      default:
        return 'Operation completed successfully';
    }
  }

  String _failureMessage(String operation) =>
      state.settings.language.startsWith('ar')
          ? 'عذراً، فشلت العملية'
          : 'Sorry, operation failed';

  Future<void> updateSettings(VoiceSettings settings) async {
    state = state.copyWith(settings: settings);
    await _persistSettings();
    await _tts.setLanguage(settings.language);
    await _tts.setSpeechRate(settings.speechRate);
    await _tts.setPitch(settings.pitch);
  }

  Future<void> toggleVoiceFeedback(bool enabled) async =>
      updateSettings(state.settings.copyWith(voiceFeedback: enabled));

  Future<void> toggleAutoSpeak(bool enabled) async =>
      updateSettings(state.settings.copyWith(autoSpeak: enabled));

  Future<void> toggleWakeWord(bool enabled) async =>
      updateSettings(state.settings.copyWith(wakeWordEnabled: enabled));

  Future<void> setLanguage(String language) async =>
      updateSettings(state.settings.copyWith(language: language));

  Future<void> setSpeechRate(double rate) async =>
      updateSettings(state.settings.copyWith(speechRate: rate));

  Future<void> setPitch(double pitch) async =>
      updateSettings(state.settings.copyWith(pitch: pitch));

  Future<List<Map<String, String>>> getAvailableVoices() async {
    final voices = await _tts.getVoices;
    if (voices is List) {
      return voices
          .map((voice) => {
                'name': voice['name']?.toString() ?? '',
                'locale': voice['locale']?.toString() ?? '',
              })
          .toList();
    }
    return [];
  }

  Future<List<String>> getAvailableLanguages() async {
    final languages = await _tts.getLanguages;
    if (languages is List) {
      return languages.map((language) => language.toString()).toList();
    }
    return [];
  }

  @override
  void dispose() {
    unawaited(_stt.stop().catchError((_) {}));
    unawaited(_tts.stop().catchError((_) {}));
    _transcriptionController.close();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceService, VoiceState>(
  (_) => VoiceService(),
);
