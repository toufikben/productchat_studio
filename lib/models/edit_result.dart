class EditResult {
  final bool ok;
  final String? outputPath;
  final String? error;
  final int creditsUsed;
  final Duration? duration;

  const EditResult({
    required this.ok,
    this.outputPath,
    this.error,
    this.creditsUsed = 0,
    this.duration,
  });

  const EditResult.failure(String message)
      : ok = false,
        outputPath = null,
        error = message,
        creditsUsed = 0,
        duration = null;
}
