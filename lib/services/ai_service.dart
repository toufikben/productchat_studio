import '../models/edit_request.dart';
import '../models/edit_result.dart';
import 'seika_service.dart';

/// Adapts editor operations to the local Seika bridge.
///
/// This service deliberately returns an [EditResult] instead of treating the
/// input path as a successful output. That keeps native failures visible to
/// the editor and prevents corrupt history entries.
class AiService {
  final SeikaService _seika;

  AiService({SeikaService? seika}) : _seika = seika ?? SeikaService();

  Future<EditResult> apply(
    String imagePath,
    EditOp op, {
    String? maskPath,
  }) {
    if (imagePath.isEmpty) {
      return Future.value(const EditResult.failure('An image path is required.'));
    }
    switch (op) {
      case EditOp.removeBg:
        return _seika.removeBackground(imagePath);
      case EditOp.enhance:
        return _seika.upscale(imagePath, factor: 2);
      case EditOp.shadow:
        return _seika.addShadow(imagePath);
      case EditOp.export:
        return _seika.export(imagePath, format: 'jpg', size: 2000);
      case EditOp.inpaint:
      case EditOp.relight:
        if (maskPath == null || maskPath.isEmpty) {
          return Future.value(const EditResult.failure(
              'A mask is required for this operation.'));
        }
        return _seika.conversationalEdit(
          imagePath: imagePath,
          maskPath: maskPath,
        );
    }
  }
}
