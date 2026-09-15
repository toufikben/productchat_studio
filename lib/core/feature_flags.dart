/// Central feature gates for ProductChat Studio.
class FeatureFlags {
  static const bool backgroundRemoval = true;
  static const bool shadowPresets = true;
  static const bool basicEnhance = true;
  static const bool textEditor = true;
  static const bool layerEditor = true;
  static const bool export = true;
  static const bool history = true;
  static const bool billing = true;
  static const bool modelCenter = true;
  static const bool voiceCommands = true;
  static const bool smartAnalysis = true;
  static const bool floatingNavBar = true;
  static const bool chatStudio = true;
  static const bool miGan = false;
  static const bool realEsrgan = false;
  static const bool relight = false;
  static const bool conversationalEdit = false;
  static const bool recipesAutomation = false;
  static const bool compliance = false;
  static const bool batchProcessing = false;
  static const bool brandIdentity = false;
  static const bool referral = false;
  static const bool useWatermark = true;
  static const bool useQuota = true;
  static const int freeQuota = 3;

  static bool isEnabled(String featureName) {
    const values = <String, bool>{
      'backgroundRemoval': backgroundRemoval, 'shadowPresets': shadowPresets,
      'basicEnhance': basicEnhance, 'textEditor': textEditor, 'layerEditor': layerEditor,
      'export': export, 'history': history, 'billing': billing, 'modelCenter': modelCenter,
      'voiceCommands': voiceCommands, 'smartAnalysis': smartAnalysis,
      'floatingNavBar': floatingNavBar, 'chatStudio': chatStudio, 'miGan': miGan,
      'realEsrgan': realEsrgan, 'relight': relight, 'conversationalEdit': conversationalEdit,
      'recipesAutomation': recipesAutomation, 'compliance': compliance,
      'batchProcessing': batchProcessing, 'brandIdentity': brandIdentity, 'referral': referral,
    };
    return values[featureName] ?? false;
  }
}
