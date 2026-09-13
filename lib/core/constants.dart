class AppConstants {
  static const appName = 'ProductChat Studio';
  static const appVersion = '1.0.0';
  static const freeMonthlyQuota = 3;
  static const maxBatchImages = 100;
  // MI-GAN weights remain disabled until the upstream weight license is
  // confirmed for commercial redistribution.
  static const modelMiganUrl = '';
  static const modelLamaUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/lama_fp32.onnx';
  static const modelRealEsrganUrl =
      'https://huggingface.co/Toufikben/productchat-models/resolve/main/RealESRGAN_x4plus.pth';
  // DreamLite is excluded from commercial builds until a commercial license
  // is obtained. Its weights must not be distributed by the production app.
  static const dreamLiteEnabled = false;
}
