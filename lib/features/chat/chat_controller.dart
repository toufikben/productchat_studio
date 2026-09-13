import '../../models/edit_request.dart';
import '../../models/edit_result.dart';
import '../../services/seika_service.dart';

/// Dispatches chat commands to local image services.
/// DreamLite is deliberately absent from this controller.
class ChatController {
  final String? imagePath;
  final String? maskPath;
  final SeikaService _seika;

  ChatController({
    required this.imagePath,
    this.maskPath,
    SeikaService? seika,
  }) : _seika = seika ?? SeikaService();

  Future<EditResult> dispatch(EditRequest req) => _dispatch(req);

  Future<EditResult> _dispatch(EditRequest req) async {
    final image = imagePath;
    if (image == null || image.isEmpty) {
      return const EditResult.failure('Select an image before editing.');
    }

    switch (req.op) {
      case EditOp.inpaint:
      case EditOp.relight:
        // Conversational edits must provide a user-created or detected mask.
        return _seika.conversationalEdit(
          imagePath: image,
          maskPath: req.maskPath ?? maskPath,
          prompt: req.prompt,
        );
      case EditOp.removeBg:
        return _seika.removeBackground(image);
      case EditOp.enhance:
        return _seika.upscale(image, factor: 2);
      case EditOp.shadow:
        return _seika.addShadow(image);
      case EditOp.export:
        return _seika.export(image, format: 'jpg', size: 2000);
    }
  }
}
