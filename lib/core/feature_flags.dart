/// FeatureFlags — نظام 3 مستويات بدون إخفاء.
///
/// كل ميزة معروضة للمستخدم في واحدة من هذه الحالات:
///   • stable      — مكتملة ومختبرة
///   • beta        — تجريبية، مع شارة ⚡
///   • comingSoon  — قادمة، مع زر "أخبرني"
///   • disabled    — معطّلة تماماً (للمطور فقط)
enum FeatureTier { stable, beta, comingSoon, disabled }

class FeatureFlag {
  final String key;
  final FeatureTier tier;
  final String? betaMessage;
  final DateTime? expectedRelease;

  const FeatureFlag({
    required this.key,
    required this.tier,
    this.betaMessage,
    this.expectedRelease,
  });

  bool get isEnabled =>
      tier == FeatureTier.stable || tier == FeatureTier.beta;
  bool get isBeta => tier == FeatureTier.beta;
  bool get isComingSoon => tier == FeatureTier.comingSoon;
}

class FeatureFlags {
  // ═══════════════════════════════════════════════════════════════
  // Registry — كل ميزة وحالتها
  // ═══════════════════════════════════════════════════════════════
  static const Map<String, FeatureFlag> _registry = {
    // ─── ✅ Stable ───
    'backgroundRemoval': FeatureFlag(
      key: 'backgroundRemoval',
      tier: FeatureTier.stable,
    ),
    'basicEnhance': FeatureFlag(
      key: 'basicEnhance',
      tier: FeatureTier.stable,
    ),
    'shadowPresets': FeatureFlag(
      key: 'shadowPresets',
      tier: FeatureTier.stable,
    ),
    'textEditor': FeatureFlag(
      key: 'textEditor',
      tier: FeatureTier.stable,
    ),
    'layerEditor': FeatureFlag(
      key: 'layerEditor',
      tier: FeatureTier.stable,
    ),
    'export': FeatureFlag(
      key: 'export',
      tier: FeatureTier.stable,
    ),
    'history': FeatureFlag(
      key: 'history',
      tier: FeatureTier.stable,
    ),
    'billing': FeatureFlag(
      key: 'billing',
      tier: FeatureTier.stable,
    ),
    'modelCenter': FeatureFlag(
      key: 'modelCenter',
      tier: FeatureTier.stable,
    ),
    'voiceCommands': FeatureFlag(
      key: 'voiceCommands',
      tier: FeatureTier.stable,
    ),
    'smartAnalysis': FeatureFlag(
      key: 'smartAnalysis',
      tier: FeatureTier.stable,
    ),
    'filters': FeatureFlag(
      key: 'filters',
      tier: FeatureTier.stable,
    ),
    'cropRotate': FeatureFlag(
      key: 'cropRotate',
      tier: FeatureTier.stable,
    ),
    'backgroundBlur': FeatureFlag(
      key: 'backgroundBlur',
      tier: FeatureTier.stable,
    ),
    'zipExport': FeatureFlag(
      key: 'zipExport',
      tier: FeatureTier.stable,
    ),
    'exif': FeatureFlag(
      key: 'exif',
      tier: FeatureTier.stable,
    ),
    'watermark': FeatureFlag(
      key: 'watermark',
      tier: FeatureTier.stable,
    ),
    'chatStudio': FeatureFlag(
      key: 'chatStudio',
      tier: FeatureTier.stable,
    ),
    'floatingNavBar': FeatureFlag(
      key: 'floatingNavBar',
      tier: FeatureTier.stable,
    ),
    'floatingNavBar': FeatureFlag(
      key: 'floatingNavBar',
      tier: FeatureTier.stable,
    ),

    // ─── ⚡ Beta ───
    'miGan': FeatureFlag(
      key: 'miGan',
      tier: FeatureTier.beta,
      betaMessage: 'First use requires ~80MB model download',
    ),
    'lamaInpaint': FeatureFlag(
      key: 'lamaInpaint',
      tier: FeatureTier.beta,
      betaMessage: 'First use requires ~105MB model download',
    ),
    'realEsrgan': FeatureFlag(
      key: 'realEsrgan',
      tier: FeatureTier.beta,
      betaMessage: 'First use requires ~64MB model download',
    ),
    'qwenEdit': FeatureFlag(
      key: 'qwenEdit',
      tier: FeatureTier.beta,
      betaMessage: 'Requires internet connection',
    ),
    'batchProcessing': FeatureFlag(
      key: 'batchProcessing',
      tier: FeatureTier.beta,
      betaMessage: 'Beta: batches up to 50 images recommended',
    ),
    'brandIdentity': FeatureFlag(
      key: 'brandIdentity',
      tier: FeatureTier.beta,
      betaMessage: 'Beta — your feedback helps us improve',
    ),
    'recipesAutomation': FeatureFlag(
      key: 'recipesAutomation',
      tier: FeatureTier.beta,
      betaMessage: 'One-tap recipes — beta quality',
    ),
    'relightAdvanced': FeatureFlag(
      key: 'relightAdvanced',
      tier: FeatureTier.beta,
      betaMessage: 'Advanced lighting — feedback appreciated',
    ),

    // ─── 🚧 Coming Soon ───
    'conversationalEdit': FeatureFlag(
      key: 'conversationalEdit',
      tier: FeatureTier.comingSoon,
    ),
    'referral': FeatureFlag(
      key: 'referral',
      tier: FeatureTier.comingSoon,
    ),
    'marketplace': FeatureFlag(
      key: 'marketplace',
      tier: FeatureTier.comingSoon,
    ),
  };

  // ═══════════════════════════════════════════════════════════════
  // Remote Overrides
  // ═══════════════════════════════════════════════════════════════
  static Map<String, String> _remoteOverrides = {};

  static void applyRemoteOverrides(Map<String, String> overrides) {
    _remoteOverrides = Map<String, String>.from(overrides);
  }

  static void clearRemoteOverrides() {
    _remoteOverrides = {};
  }

  // ═══════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════

  static FeatureFlag flag(String key) {
    final base = _registry[key] ??
        FeatureFlag(key: key, tier: FeatureTier.disabled);
    final remoteTierStr = _remoteOverrides[key];
    if (remoteTierStr == null) return base;
    return FeatureFlag(
      key: base.key,
      tier: _tierFromString(remoteTierStr),
      betaMessage: base.betaMessage,
      expectedRelease: base.expectedRelease,
    );
  }

  static bool isEnabled(String key) => flag(key).isEnabled;
  static bool isBeta(String key) => flag(key).isBeta;
  static bool isComingSoon(String key) => flag(key).isComingSoon;
  static bool get backgroundRemoval => isEnabled('backgroundRemoval');
  static bool get basicEnhance => isEnabled('basicEnhance');
  static bool get shadowPresets => isEnabled('shadowPresets');
  static bool get textEditor => isEnabled('textEditor');
  static bool get layerEditor => isEnabled('layerEditor');
  static bool get export => isEnabled('export');
  static bool get history => isEnabled('history');
  static bool get billing => isEnabled('billing');
  static bool get modelCenter => isEnabled('modelCenter');
  static bool get voiceCommands => isEnabled('voiceCommands');
  static bool get smartAnalysis => isEnabled('smartAnalysis');
  static bool get chatStudio => isEnabled('chatStudio');
  static bool get miGan => isEnabled('miGan');
  static bool get realEsrgan => isEnabled('realEsrgan');
  static bool get relight => isEnabled('relightAdvanced');
  static bool get conversationalEdit => isEnabled('conversationalEdit');
  static bool get recipesAutomation => isEnabled('recipesAutomation');
  static bool get compliance => isEnabled('compliance');
  static bool get batchProcessing => isEnabled('batchProcessing');
  static bool get brandIdentity => isEnabled('brandIdentity');
  static bool get referral => isEnabled('referral');
  static bool get useWatermark => isEnabled('watermark');
  static bool get useQuota => true;
  static int get freeQuota => 3;
  static bool get floatingNavBar => isEnabled('floatingNavBar');
  static bool get batchProcessing => isEnabled('batchProcessing');
  static bool get floatingNavBar => isEnabled('floatingNavBar');

  static List<FeatureFlag> get allFeatures =>
      _registry.values.toList(growable: false);

  static List<FeatureFlag> get betaFeatures =>
      _registry.values.where((f) => f.isBeta).toList(growable: false);

  static List<FeatureFlag> get comingSoonFeatures =>
      _registry.values.where((f) => f.isComingSoon).toList(growable: false);

  static FeatureTier _tierFromString(String s) {
    switch (s.toLowerCase()) {
      case 'stable':
        return FeatureTier.stable;
      case 'beta':
        return FeatureTier.beta;
      case 'comingsoon':
      case 'coming_soon':
        return FeatureTier.comingSoon;
      default:
        return FeatureTier.disabled;
    }
  }
}
