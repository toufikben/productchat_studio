class AppConstants {
  static const appName = 'ProductChat Studio';
  static const appVersion = '1.0.0';
  static const buildNumber = 1;

  // ─── Quotas & Credits ───
  static const freeMonthlyQuota = 3;
  static const creditsPerBackgroundFast = 1;
  static const creditsPerBackgroundPro = 2;
  static const creditsPerBackgroundUltra = 3;
  static const creditsPerEnhance = 2;
  static const creditsPerConversational = 3;
  static const creditsPerShadow = 1;
  static const creditsPerRelight = 2;
  static const creditsPerColorize = 2;
  static const creditsPerInpaint = 3;
  static const creditsPerCompliance = 0;
  static const creditsPerExport = 0;
  static const freeHasWatermark = true;
  static const freeUsesPatchMatchOnly = true;
  static const creditsPerBackground = creditsPerBackgroundFast;

  // ─── IAP Product IDs (must match Play Console exactly) ───
  static const iapProMonthly = 'pro_monthly';
  static const iapProYearly = 'pro_yearly';
  static const iapCredits100 = 'credits_100';
  static const iapCredits500 = 'credits_500';
  static const iapCredits1200 = 'credits_1200';
  static const iapLifetime = 'lifetime';

  // ─── Display names ───
  static const displayNames = {
    iapProMonthly: 'Pro Monthly',
    iapProYearly: 'Pro Yearly',
    iapCredits100: '100 Credits',
    iapCredits500: '500 Credits',
    iapCredits1200: '1200 Credits',
    iapLifetime: 'Lifetime Access',
  };

  // ─── Fallback prices (USD) ───
  static const fallbackPrices = {
    iapProMonthly: r'$4.99',
    iapProYearly: r'$29.99',
    iapCredits100: r'$4.99',
    iapCredits500: r'$19.99',
    iapCredits1200: r'$39.99',
    iapLifetime: r'$79.99',
  };

  static const creditsPerPack = {
    iapCredits100: 100,
    iapCredits500: 500,
    iapCredits1200: 1200,
  };

  static const proMonthlyDays = 30;
  static const proYearlyDays = 365;

  // ─── Model URLs ───
  static const modelMiganUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/migan.onnx';
  static const modelLamaUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/lama_fp16.onnx';
  static const modelRealEsrganUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/real_esrgan_x4.onnx';
  static const modelQwenEditUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/qwen_edit_int8.onnx';

  // ─── SHA-256 for committed Hugging Face artifacts ───
  static const modelMiganSha256 =
      '593eba0b7e04730f1b61c0a3cbca68d97d8d6a7ff5c6a44a7b9d7fcd880fc5ae';
  static const modelLamaSha256 =
      '37f2e4888eb27aa08841786b506fa094156c497de3d954ebf7a297c61a7fb4ea';
  static const modelRealEsrganSha256 =
      '5c586662929cbc686c1a5c38d9c060dbdb4ea5863a1f7672b8c0761e6b89c033';
  static const modelQwenEditSha256 = 'REPLACE_AFTER_UPLOAD';
  static const dreamLiteEnabled = false;

  // ─── Limits ───
  static const maxBatchImages = 100;
  static const maxHistoryItems = 100;
  static const maxReferralRewards = 50;
  static const referralCreditsPerInvite = 20;
  static const maxLayers = 10;
  static const maxUndoSteps = 30;
}
