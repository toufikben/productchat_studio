enum EditOp { relight, enhance, removeBg, shadow, export, inpaint }

class EditRequest {
  final EditOp op;
  final String? prompt;
  final String? maskPath;

  const EditRequest({required this.op, this.prompt, this.maskPath});
}
