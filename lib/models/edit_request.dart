enum EditOp {
  removeBg,
  enhance,
  shadow,
  relight,
  colorize,
  export,
  batch,
  recipe,
  conversational,
  inpaint,
}

class EditRequest {
  final EditOp op;
  final String? prompt;
  final Map<String, dynamic> params;

  const EditRequest({
    required this.op,
    this.prompt,
    this.params = const {},
  });
}

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

  const EditResult.failure(this.error)
      : ok = false,
        outputPath = null,
        creditsUsed = 0,
        duration = null;

  const EditResult.success({
    required this.outputPath,
    this.creditsUsed = 0,
    this.duration,
  })  : ok = true,
        error = null;
}

class HistoryItem {
  final String id;
  final String inputPath;
  final String outputPath;
  final EditOp op;
  final DateTime timestamp;

  const HistoryItem({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    required this.op,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'input': inputPath,
        'output': outputPath,
        'op': op.name,
        'ts': timestamp.toIso8601String(),
      };

  factory HistoryItem.fromMap(Map<dynamic, dynamic> m) => HistoryItem(
        id: m['id'] as String? ?? '',
        inputPath: m['input'] as String? ?? '',
        outputPath: m['output'] as String? ?? '',
        op: EditOp.values.firstWhere(
          (e) => e.name == m['op'],
          orElse: () => EditOp.removeBg,
        ),
        timestamp:
            DateTime.tryParse(m['ts'] as String? ?? '') ?? DateTime.now(),
      );
}
