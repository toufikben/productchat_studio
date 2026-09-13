class AppConstants {
  static const appName = 'ProductChat Studio';
  static const appVersion = '1.0.0';
  static const freeMonthlyQuota = 3;
  static const maxBatchImages = 100;
  static const modelMiganUrl = 'https://huggingface.co/YOUR_ORG/productchat-models/resolve/main/migan.onnx';
  static const modelLamaUrl = 'https://huggingface.co/YOUR_ORG/productchat-models/resolve/main/lama_fp16.onnx';
  // DreamLite is excluded from commercial builds until a commercial license
  // is obtained. Its weights must not be distributed by the production app.
  static const dreamLiteEnabled = false;
}
