import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/services/voice_service.dart';

void main() {
  group('VoiceState', () {
    test('starts with default values', () {
      const state = VoiceState();
      expect(state.isListening, false);
      expect(state.isSpeaking, false);
      expect(state.lastTranscription, '');
      expect(state.lastError, '');
    });

    test('copyWith updates isListening', () {
      const state = VoiceState();
      final updated = state.copyWith(isListening: true);
      expect(updated.isListening, true);
      expect(updated.isSpeaking, false);
    });

    test('copyWith updates lastTranscription', () {
      const state = VoiceState();
      final updated = state.copyWith(lastTranscription: 'hello');
      expect(updated.lastTranscription, 'hello');
    });

    test('copyWith preserves unchanged fields', () {
      const state = VoiceState(isListening: true, lastTranscription: 'test');
      final updated = state.copyWith(isSpeaking: true);
      expect(updated.isListening, true);
      expect(updated.lastTranscription, 'test');
      expect(updated.isSpeaking, true);
    });
  });

  group('VoiceService', () {
    test('initial state is default', () {
      final service = VoiceService();
      expect(service.state.isListening, false);
      expect(service.state.isSpeaking, false);
      service.dispose();
    });

    test('state starts with empty transcription', () {
      final service = VoiceService();
      expect(service.state.lastTranscription, '');
      service.dispose();
    });
  });
}
