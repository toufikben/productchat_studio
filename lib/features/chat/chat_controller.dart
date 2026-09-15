import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/edit_request.dart';
import '../../services/ai_service.dart';
import '../../services/ai/migan_service.dart';
import '../../services/ai/qwen_edit_service.dart';
import '../../services/ai/relight_service.dart';
import '../../services/ai/colorize_service.dart';
import '../../services/compliance_service.dart';
import '../../services/product_fidelity_service.dart';
import '../../services/smart_analysis_service.dart';
import '../../services/storage_service.dart';
import '../../services/pro_service.dart';
import '../../services/billing_service.dart';

class ChatMessage {
  final String id, role, text;
  final DateTime at;
  ChatMessage({required this.role, required this.text})
      : id = const Uuid().v4(),
        at = DateTime.now();
}

class ChatState {
  final List<ChatMessage> messages;
  final String? imagePath, lastError;
  final bool busy;
  final int credits;
  final AnalysisResult? analysisResult;
  final FidelityResult? lastFidelity;

  const ChatState({
    this.messages = const [],
    this.imagePath,
    this.lastError,
    this.busy = false,
    this.credits = 0,
    this.analysisResult,
    this.lastFidelity,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? imagePath,
    String? lastError,
    bool? busy,
    int? credits,
    AnalysisResult? analysisResult,
    FidelityResult? lastFidelity,
    bool clearAnalysis = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        imagePath: imagePath ?? this.imagePath,
        lastError: lastError,
        busy: busy ?? this.busy,
        credits: credits ?? this.credits,
        analysisResult:
            clearAnalysis ? null : (analysisResult ?? this.analysisResult),
        lastFidelity: lastFidelity ?? this.lastFidelity,
      );
}

class ChatController extends StateNotifier<ChatState> {
  ChatController({String? imagePath, BillingService? billing})
      : super(ChatState(imagePath: imagePath)) {
    _init();
  }

  final _border = BorderCutService();
  final _migan = MIGanService();
  final _seika = SeikaService(quality: 'best');
  final _qwen = QwenEditService();
  final _enhance = BasicEnhanceService();
  final _upscale = UpscaleService();
  final _shadow = ShadowService();
  final _relight = RelightService();
  final _colorize = ColorizeService();
  final _fidelity = ProductFidelityService();
  final _export = ExportService();
  final _store = StorageService();
  final _smart = SmartAnalysisService();
  final _pro = ProService();
  final _stt = SpeechToText();

  Future<void> _init() async {
    state = state.copyWith(
      credits: _store.getCredits(),
      messages: [
        ChatMessage(
            role: 'assistant',
            text: 'Welcome! Upload a product photo and I\'ll analyze it.'),
      ],
    );
  }

  Future<void> pickImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 95);
    if (x == null) return;

    state = state.copyWith(
      imagePath: x.path,
      lastError: null,
      messages: [
        ...state.messages,
        ChatMessage(role: 'user', text: '📎 Image uploaded'),
      ],
    );

    final analysis = await _smart.analyze(x.path);
    if (!mounted) return;
    state = state.copyWith(analysisResult: analysis);
  }

  Future<void> dismissAnalysis() async {
    state = state.copyWith(clearAnalysis: true);
  }

  Future<EditResult> dispatch(EditRequest request) async {
    if (state.imagePath == null || state.imagePath!.trim().isEmpty) {
      return const EditResult.failure('Select an image first');
    }
    if ((request.op == EditOp.inpaint || request.op == EditOp.conversational) &&
        (request.params['maskPath'] as String?)?.trim().isEmpty != false) {
      return const EditResult.failure('A real mask is required');
    }
    return _dispatch(request);
  }

  Future<void> voiceInput() async {
    if (!await _stt.initialize()) return;
    await _stt.listen(onResult: (r) {
      if (r.finalResult) submit(r.recognizedWords);
    });
  }

  Future<void> submit(String text) async {
    if (text.trim().isEmpty) return;
    state = state.copyWith(messages: [
      ...state.messages,
      ChatMessage(role: 'user', text: text),
    ]);

    if (state.imagePath == null) {
      state = state.copyWith(messages: [
        ...state.messages,
        ChatMessage(role: 'assistant', text: 'Upload an image first 📸'),
      ]);
      return;
    }

    final req = _parse(text);
    final cost = _creditCost(req.op);

    if (!_canUseFeature(req.op, cost)) {
      state = state.copyWith(messages: [
        ...state.messages,
        ChatMessage(role: 'assistant', text: _gateMessage(req.op, cost)),
      ]);
      return;
    }

    state = state.copyWith(busy: true, lastError: null);
    final balanceBefore = _store.getCredits();
    if (!_pro.isPro) {
      await _store.addCredits(-cost);
      state = state.copyWith(credits: _store.getCredits());
    }

    try {
      final before = state.imagePath!;
      final res = await _dispatch(req);
      if (res.ok && res.outputPath != null) {
        final fidelity = await _fidelity.check(
          originalPath: before,
          editedPath: res.outputPath!,
        );

        _store.addHistory({
          'input': before,
          'output': res.outputPath,
          'op': req.op.name,
          'ts': DateTime.now().toIso8601String(),
        });

        state = state.copyWith(
          imagePath: res.outputPath,
          credits: _store.getCredits(),
          lastFidelity: fidelity,
          clearAnalysis: true,
          messages: [
            ...state.messages,
            ChatMessage(
              role: 'assistant',
              text: '✅ Done in ${res.duration?.inMilliseconds ?? 0}ms',
            ),
          ],
        );
      } else {
        if (!_pro.isPro) {
          await _store.setCredits(balanceBefore);
          state = state.copyWith(credits: _store.getCredits());
        }
        state = state.copyWith(
          lastError: res.error,
          messages: [
            ...state.messages,
            ChatMessage(
                role: 'assistant',
                text: '❌ ${res.error ?? 'Unknown'} (refunded)'),
          ],
        );
      }
    } catch (e) {
      if (!_pro.isPro) {
        await _store.setCredits(balanceBefore);
        state = state.copyWith(credits: _store.getCredits());
      }
      state = state.copyWith(lastError: '$e');
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  EditRequest _parse(String t) {
    final s = t.toLowerCase();
    if (s.contains('background') || s.contains('bg') || s.contains('خلفية')) {
      return const EditRequest(op: EditOp.removeBg);
    }
    if (s.contains('relight') || s.contains('إضاءة') || s.contains('light')) {
      final style = s.contains('warm')
          ? 'warm'
          : s.contains('cool')
              ? 'cool'
              : s.contains('natural')
                  ? 'natural'
                  : s.contains('dramatic')
                      ? 'dramatic'
                      : 'studio';
      return EditRequest(op: EditOp.relight, params: {'style': style});
    }
    if (s.contains('colorize') || s.contains('تلوين') || s.contains('color')) {
      return const EditRequest(op: EditOp.colorize);
    }
    if (s.contains('enhance') ||
        s.contains('upscale') ||
        s.contains('تحسين') ||
        s.contains('دقة')) {
      return const EditRequest(op: EditOp.enhance);
    }
    if (s.contains('shadow') || s.contains('ظل')) {
      return const EditRequest(op: EditOp.shadow);
    }
    if (s.contains('amazon') || s.contains('etsy') || s.contains('فحص')) {
      return const EditRequest(op: EditOp.export);
    }
    return EditRequest(op: EditOp.conversational, prompt: t);
  }

  int _creditCost(EditOp op) => switch (op) {
        EditOp.removeBg => AppConstants.creditsPerBackgroundFast,
        EditOp.enhance => AppConstants.creditsPerEnhance,
        EditOp.shadow => AppConstants.creditsPerShadow,
        EditOp.relight => 2,
        EditOp.colorize => 2,
        EditOp.conversational => AppConstants.creditsPerConversational,
        EditOp.inpaint => 3,
        EditOp.export => 0,
        EditOp.recipe => AppConstants.creditsPerConversational,
        EditOp.batch => 1,
      };

  bool _canUseFeature(EditOp op, int cost) {
    if (_pro.isPro) return true;
    const proOnly = {
      EditOp.conversational,
      EditOp.inpaint,
      EditOp.relight,
      EditOp.colorize,
    };
    if (proOnly.contains(op)) return false;
    return _store.getCredits() >= cost;
  }

  String _gateMessage(EditOp op, int cost) {
    if (!_pro.isPro) {
      const proOnly = {
        EditOp.conversational,
        EditOp.inpaint,
        EditOp.relight,
        EditOp.colorize,
      };
      if (proOnly.contains(op)) {
        return 'This feature requires Pro. Tap the pill to upgrade.';
      }
      if (_store.getCredits() < cost) {
        return 'Need $cost credits. You have ${_store.getCredits()}.';
      }
    }
    return 'Cannot perform operation.';
  }

  Future<EditResult> _dispatch(EditRequest req) async {
    final path = state.imagePath!;
    switch (req.op) {
      case EditOp.removeBg:
        return _border.removeBg(path);
      case EditOp.enhance:
        return _enhance.enhance(path, factor: 2);
      case EditOp.shadow:
        return _shadow.addShadow(path,
            type: req.params['type'] as String? ?? 'natural');
      case EditOp.relight:
        return _relight.relight(path,
            style: req.params['style'] as String? ?? 'studio');
      case EditOp.colorize:
        return _colorize.colorize(path);
      case EditOp.export:
        final f = await _export.export(path, format: 'jpg', size: 2000);
        return EditResult.success(outputPath: f.path, creditsUsed: 0);
      case EditOp.inpaint:
        return _seika.inpaint(path, path);
      case EditOp.conversational:
      case EditOp.recipe:
        return _qwen.run(req, path);
      case EditOp.batch:
        return EditResult.failure('Batch processing not supported here');
    }
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }
}

final chatProvider =
    StateNotifierProvider<ChatController, ChatState>((_) => ChatController());
