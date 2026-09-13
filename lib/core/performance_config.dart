/// Central performance policy for on-device image inference.
///
/// Values are deliberately conservative until real-device benchmarks exist.
class PerformanceConfig {
  const PerformanceConfig._();

  static const int maxImageDimension = 4096;
  static const int lamaInputDimension = 512;
  static const int esrganMaxDimension = 1024;
  static const int inferenceThreads = 4;
  static const int maxConcurrentInferences = 1;
  static const Duration modelLoadTimeout = Duration(minutes: 2);
  static const Duration inferenceTimeout = Duration(minutes: 3);
  static const bool preferHardwareAcceleration = true;
  static const bool allowCpuFallback = true;
}
