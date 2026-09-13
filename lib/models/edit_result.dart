class EditResult {
  final bool ok;
  final String? outputPath;
  final String? error;
  final int creditsUsed;

  const EditResult({
    required this.ok,
    this.outputPath,
    this.error,
    this.creditsUsed = 0,
  });

  const EditResult.failure(String message)
      : ok = false,
        outputPath = null,
        error = message,
        creditsUsed = 0;
}
