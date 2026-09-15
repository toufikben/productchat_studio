import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/features/settings/models_screen.dart';

void main() {
  group('ModelInfo', () {
    test('kModels contains LaMa', () {
      final lama = kModels.firstWhere((m) => m.id == 'lama');
      expect(lama.name, 'LaMa');
      expect(lama.fileName, 'lama_fp16.onnx');
    });

    test('kModels contains Real-ESRGAN', () {
      final esrgan = kModels.firstWhere((m) => m.id == 'real_esrgan');
      expect(esrgan.name, 'Real-ESRGAN');
      expect(esrgan.fileName, 'real_esrgan_x4.onnx');
    });

    test('all models have required fields', () {
      for (final m in kModels) {
        expect(m.id, isNotEmpty);
        expect(m.name, isNotEmpty);
        expect(m.url, isNotEmpty);
        expect(m.fileName, isNotEmpty);
        expect(m.size, isNotEmpty);
      }
    });
  });

  group('ModelCenterState', () {
    test('starts empty', () {
      const state = ModelCenterState();
      expect(state.states, isEmpty);
      expect(state.progress, isEmpty);
      expect(state.paths, isEmpty);
      expect(state.errors, isEmpty);
    });

    test('copyWith updates states', () {
      const state = ModelCenterState();
      final updated = state.copyWith(
        states: {'lama': ModelState.ready},
      );
      expect(updated.states['lama'], ModelState.ready);
    });

    test('copyWith preserves unchanged fields', () {
      const state = ModelCenterState(
        states: {'lama': ModelState.ready},
        progress: {'lama': 1.0},
      );
      final updated = state.copyWith(errors: {'lama': 'error'});
      expect(updated.states['lama'], ModelState.ready);
      expect(updated.progress['lama'], 1.0);
      expect(updated.errors['lama'], 'error');
    });
  });
}
