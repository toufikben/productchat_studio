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

    test('beta and coming-soon features expose their configured state', () {
      expect(FeatureFlags.miGan, true);
      expect(FeatureFlags.realEsrgan, true);
      expect(FeatureFlags.relight, true);
      expect(FeatureFlags.conversationalEdit, false);
      expect(FeatureFlags.recipesAutomation, true);
      expect(FeatureFlags.compliance, false);
      expect(FeatureFlags.batchProcessing, true);
      expect(FeatureFlags.brandIdentity, true);
      expect(FeatureFlags.referral, false);
    });

    test('isEnabled returns correct value for enabled features', () {
      expect(FeatureFlags.isEnabled('backgroundRemoval'), true);
      expect(FeatureFlags.isEnabled('voiceCommands'), true);
      expect(FeatureFlags.isEnabled('floatingNavBar'), true);
    });

    test('isEnabled returns false for disabled features', () {
      expect(FeatureFlags.isEnabled('miGan'), true);
      expect(FeatureFlags.isEnabled('realEsrgan'), true);
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
