import '../../models/edit_request.dart';
import '../../models/edit_result.dart';
import '../../services/billing_service.dart';
import '../../services/free_watermark_service.dart';
import '../../services/history_service.dart';
import '../../services/seika_service.dart';

/// Dispatches chat commands to local image services.
///
/// Free-tier flow:
///   1. Check quota availability.
///   2. Run the operation.
///   3. Apply watermark (must succeed before quota is consumed).
///   4. Consume quota.
///   5. Record to history.
///
/// This matches the EditorController Free-tier flow so both paths behave
/// identically: watermark failure rolls back before quota is consumed.
///
/// DreamLite is deliberately absent from this controller.
class ChatController {
  final String? imagePath;
  final String? maskPath;
  final SeikaService _seika;
  final BillingService _billing;

  ChatController({
    required this.imagePath,
    this.maskPath,
    SeikaService? seika,
    BillingService? billing,
  })  : _seika = seika ?? SeikaService(),
        _billing = billing ?? billingService;

  Future<EditResult> dispatch(EditRequest req) => _dispatch(req);

  Future<EditResult> _dispatch(EditRequest req) async {
    final image = imagePath;
    if (image == null || image.isEmpty) {
      return const EditResult.failure('Select an image before editing.');
    }

    if (!_billing.proService.isPro) {
      if (req.op != EditOp.removeBg) {
        return const EditResult.failure(
          'Free tier supports PatchMatch background removal only; '
          'conversational edits require a mask and Pro.',
        );
      }
      // 1. Check quota before doing any work.
      if (!_billing.freeQuota.canUse()) {
        return const EditResult.failure(
          'Free monthly quota is exhausted. Upgrade to Pro to continue.',
        );
      }
      // 2. Run the operation.
      final result = await _seika.removeBackground(image);
      if (!result.ok || result.outputPath == null) return result;
      // 3. Apply watermark — must succeed before quota is consumed.
      final watermarked = await freeWatermarkService.apply(result.outputPath!);
      if (watermarked == null) {
        return const EditResult.failure('Unable to apply the Free watermark.');
      }
      // 4. Consume quota only after a successful, watermarked output.
      final consumed = await _billing.freeQuota.consume();
      if (!consumed) {
        return const EditResult.failure(
            'Free monthly quota changed during processing.');
      }
      // 5. Record to history.
      await historyService.record(path: watermarked, operation: 'removeBg');
      return EditResult(
        ok: true,
        outputPath: watermarked,
        creditsUsed: result.creditsUsed,
      );
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
