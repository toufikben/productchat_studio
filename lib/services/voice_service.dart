import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceState {
  final bool isListening;
  final bool isSpeaking;
  final String lastTranscription;
  final String lastError;

  const VoiceState({
    this.isListening = false,
    this.isSpeaking = false,
    this.lastTranscription = '',
    this.lastError = '',
  });

  VoiceState copyWith({
    bool? isListening,
    bool? isSpeaking,
    String? lastTranscription,
    String? lastError,
  }) =>
      VoiceState(
        isListening: isListening ?? this.isListening,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        lastTranscription: lastTranscription ?? this.lastTranscription,
        lastError: lastError ?? this.lastError,
      );
}

class VoiceService extends StateNotifier<VoiceState> {
  VoiceService() : super(const VoiceState());

  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _sttInitialized = false;

  Future<void> init() async {
    _sttInitialized = await _stt.initialize(
      onError: (e) => state = state.copyWith(lastError: e.errorMsg),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          state = state.copyWith(isListening: false);
        }
      },
    );

    await _tts.setLanguage('ar-SA');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> startListening({String localeId = 'ar-SA'}) async {
    if (!_sttInitialized) await init();
    if (!_sttInitialized) {
      state = state.copyWith(lastError: 'Speech recognition not available');
      return;
    }
    state = state.copyWith(isListening: true, lastError: '');
    await _stt.listen(
      localeId: localeId,
      onResult: (r) => state = state.copyWith(lastTranscription: r.recognizedWords),
      listenOptions: SpeechListenOptions(
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

  Future<void> speak(String text, {String locale = 'ar-SA'}) async {
    await _tts.setLanguage(locale);
    state = state.copyWith(isSpeaking: true);
    await _tts.speak(text);
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceService, VoiceState>(
  (_) => VoiceService(),
);
