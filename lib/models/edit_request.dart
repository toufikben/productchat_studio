enum EditOp { relight, enhance, removeBg, shadow, export, inpaint, colorize, conversational, recipe }

class EditRequest {
  final EditOp op;
  final String? prompt;
  final String? maskPath;
  final Map<String, dynamic> params;

  const EditRequest({
    required this.op,
    this.prompt,
    this.maskPath,
    this.params = const {},
  });
}
