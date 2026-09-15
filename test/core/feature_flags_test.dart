import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/core/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('v1.0 features are enabled', () {
      expect(FeatureFlags.backgroundRemoval, true);
      expect(FeatureFlags.shadowPresets, true);
      expect(FeatureFlags.basicEnhance, true);
      expect(FeatureFlags.textEditor, true);
      expect(FeatureFlags.layerEditor, true);
      expect(FeatureFlags.export, true);
      expect(FeatureFlags.history, true);
      expect(FeatureFlags.billing, true);
      expect(FeatureFlags.modelCenter, true);
      expect(FeatureFlags.voiceCommands, true);
      expect(FeatureFlags.smartAnalysis, true);
      expect(FeatureFlags.floatingNavBar, true);
      expect(FeatureFlags.chatStudio, true);
    });

    test('pending features are disabled', () {
      expect(FeatureFlags.miGan, false);
      expect(FeatureFlags.realEsrgan, false);
      expect(FeatureFlags.relight, false);
      expect(FeatureFlags.conversationalEdit, false);
      expect(FeatureFlags.recipesAutomation, false);
      expect(FeatureFlags.compliance, false);
      expect(FeatureFlags.batchProcessing, false);
      expect(FeatureFlags.brandIdentity, false);
      expect(FeatureFlags.referral, false);
    });

    test('isEnabled returns correct value for enabled features', () {
      expect(FeatureFlags.isEnabled('backgroundRemoval'), true);
      expect(FeatureFlags.isEnabled('voiceCommands'), true);
      expect(FeatureFlags.isEnabled('floatingNavBar'), true);
    });

    test('isEnabled returns false for disabled features', () {
      expect(FeatureFlags.isEnabled('miGan'), false);
      expect(FeatureFlags.isEnabled('realEsrgan'), false);
      expect(FeatureFlags.isEnabled('compliance'), false);
    });

    test('isEnabled returns false for unknown features', () {
      expect(FeatureFlags.isEnabled('unknownFeature'), false);
    });

    test('watermark is enabled', () {
      expect(FeatureFlags.useWatermark, true);
    });

    test('free quota is 3', () {
      expect(FeatureFlags.useQuota, true);
      expect(FeatureFlags.freeQuota, 3);
    });
  });
}
