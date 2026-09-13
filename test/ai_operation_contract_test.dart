import 'package:flutter_test/flutter_test.dart';
import 'package:productchat_studio/features/chat/chat_controller.dart';
import 'package:productchat_studio/models/edit_request.dart';
import 'package:productchat_studio/services/ai_service.dart';

void main() {
  test('AI service rejects an empty image path without calling native code', () async {
    final result = await AiService().apply('', EditOp.removeBg);

    expect(result.ok, isFalse);
    expect(result.outputPath, isNull);
    expect(result.error, contains('image path'));
  });

  test('AI service requires a mask for conversational editor operations', () async {
    final result = await AiService().apply('/tmp/image.png', EditOp.relight);

    expect(result.ok, isFalse);
    expect(result.outputPath, isNull);
    expect(result.error, contains('mask'));
  });

  test('chat dispatch fails safely when no image is selected', () async {
    final controller = ChatController(imagePath: null);
    final result = await controller.dispatch(
      const EditRequest(op: EditOp.removeBg),
    );

    expect(result.ok, isFalse);
    expect(result.error, contains('Select an image'));
  });

  test('chat conversational edit requires a real mask', () async {
    final controller = ChatController(imagePath: '/tmp/image.png');
    final result = await controller.dispatch(
      const EditRequest(op: EditOp.inpaint),
    );

    expect(result.ok, isFalse);
    expect(result.error, contains('mask'));
  });
}
