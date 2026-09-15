class AppConstants {
  static const appName = 'ProductChat Studio';
  static const appVersion = '1.0.0';

  // Free tier policy from Billing v2.
  static const freeMonthlyQuota = 3;
  static const freeHasWatermark = true;
  static const freeUsesPatchMatchOnly = true;

  // Product limits and operation economics.
  static const maxBatchImages = 100;
  static const creditsPerBackground = 1;
  static const creditsPerShadow = 1;
  static const creditsPerEnhance = 2;
  static const creditsPerConversational = 3;
  static const creditsPerCompliance = 0;
  static const creditsPerExport = 0;

  static const iapProMonthly = 'pro_monthly';
  static const iapProYearly = 'pro_yearly';
  static const iapCredits100 = 'credits_100';
  static const iapCredits500 = 'credits_500';
  static const iapCredits1200 = 'credits_1200';
  static const iapLifetime = 'lifetime';

  static const creditsPerPack = <String, int>{
    iapCredits100: 100,
    iapCredits500: 500,
    iapCredits1200: 1200,
  };

  // MI-GAN weights remain disabled until the upstream weight license is
  // confirmed for commercial redistribution.
  static const modelMiganUrl = '';
  static const modelLamaUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/lama_fp32.onnx';
  static const modelRealEsrganUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/real_esrgan_x4.onnx';
  static const modelRealEsrganSha256 = 'REPLACE_AFTER_UPLOAD';
  // DreamLite is excluded from commercial builds until a commercial license
  // is obtained. Its weights must not be distributed by the production app.
  static const dreamLiteEnabled = false;
}
