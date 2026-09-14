import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai_service.dart';
import '../../services/billing_service.dart';
import '../../services/free_watermark_service.dart';
import '../../services/history_service.dart';
import '../../models/edit_request.dart';

class EditorText {
  final String id;
  final String text;
  final Offset position;
  final double fontSize;
  final Color color;
  final bool bold;
  const EditorText(
      {required this.id,
      required this.text,
      this.position = const Offset(40, 40),
      this.fontSize = 28,
      this.color = Colors.white,
      this.bold = true});
  EditorText copyWith(
          {String? text,
          Offset? position,
          double? fontSize,
          Color? color,
          bool? bold}) =>
      EditorText(
          id: id,
          text: text ?? this.text,
          position: position ?? this.position,
          fontSize: fontSize ?? this.fontSize,
          color: color ?? this.color,
          bold: bold ?? this.bold);
}

class EditorState {
  final String? imagePath, originalPath, error;
  final List<String> history;
  final int historyIndex;
  final List<EditorText> texts;
  final int? selectedTextIndex;
  final bool showLayers, showBefore, busy;
  const EditorState(
      {this.imagePath,
      this.originalPath,
      this.history = const [],
      this.historyIndex = -1,
      this.texts = const [],
      this.selectedTextIndex,
      this.showLayers = false,
      this.showBefore = false,
      this.busy = false,
      this.error});
  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex >= 0 && historyIndex < history.length - 1;
  EditorState copyWith(
          {String? imagePath,
          String? originalPath,
          String? error,
          List<String>? history,
          int? historyIndex,
          List<EditorText>? texts,
          int? selectedTextIndex,
          bool clearSelection = false,
          bool? showLayers,
          bool? showBefore,
          bool? busy}) =>
      EditorState(
          imagePath: imagePath ?? this.imagePath,
          originalPath: originalPath ?? this.originalPath,
          error: error,
          history: history ?? this.history,
          historyIndex: historyIndex ?? this.historyIndex,
          texts: texts ?? this.texts,
          selectedTextIndex: clearSelection
              ? null
              : (selectedTextIndex ?? this.selectedTextIndex),
          showLayers: showLayers ?? this.showLayers,
          showBefore: showBefore ?? this.showBefore,
          busy: busy ?? this.busy);
}

class EditorController extends StateNotifier<EditorState> {
  EditorController() : super(const EditorState());
  final _ai = AiService();
  void loadImage(String path) => state = state.copyWith(
      imagePath: path, originalPath: path, history: [path], historyIndex: 0);
  Future<void> _apply(EditOp op) async {
    final path = state.imagePath;
    if (path == null) return;
    final cost = _costFor(op);
    final isPro = billingService.proService.isPro;
    if (!isPro && op != EditOp.removeBg) {
      state = state.copyWith(
        error: 'Free tier supports PatchMatch background removal only.',
      );
      return;
    }
    if (!isPro && !billingService.freeQuota.canUse()) {
      state = state.copyWith(
        error: 'Free monthly quota is exhausted. Upgrade to Pro to continue.',
      );
      return;
    }
    if (isPro && !billingService.canSpend(cost)) {
      state = state.copyWith(error: 'Not enough credits. Please open the Credits screen.');
      return;
    }
    state = state.copyWith(busy: true);
    try {
      final result = await _ai.apply(path, op);
      if (result.ok && result.outputPath != null) {
        var outputPath = result.outputPath!;
        if (!isPro && op == EditOp.removeBg) {
          final watermarked = await freeWatermarkService.apply(outputPath);
          if (watermarked == null) {
            state = state.copyWith(error: 'Unable to apply the Free watermark.');
            return;
          }
          outputPath = watermarked;
        }
        final spent = !isPro && op == EditOp.removeBg
            ? await billingService.freeQuota.consume()
            : await billingService.spend(result.creditsUsed);
        if (spent || result.creditsUsed == 0) {
          await _push(outputPath, op.name);
        } else {
          state = state.copyWith(error: 'Credits changed before the operation completed.');
        }
      } else {
        state = state.copyWith(error: result.error ?? 'Image operation failed.');
      }
    } finally {
      if (mounted) state = state.copyWith(busy: false);
    }
  }

  int _costFor(EditOp op) {
    switch (op) {
      case EditOp.removeBg:
      case EditOp.shadow:
        return 1;
      case EditOp.enhance:
        return 2;
      case EditOp.export:
        return 0;
      case EditOp.inpaint:
      case EditOp.relight:
        return 3;
    }
  }

  Future<void> _push(String path, String operation) async {
    final items = [...state.history.take(state.historyIndex + 1), path];
    state = state.copyWith(
        imagePath: path, history: items, historyIndex: items.length - 1);
    await historyService.record(path: path, operation: operation);
  }

  Future<void> removeBg() => _apply(EditOp.removeBg);
  Future<void> addShadow() => _apply(EditOp.shadow);
  Future<void> enhance() => _apply(EditOp.enhance);
  Future<void> relight() => _apply(EditOp.relight);
  void undo() {
    if (state.canUndo) {
      state = state.copyWith(
          imagePath: state.history[state.historyIndex - 1],
          historyIndex: state.historyIndex - 1);
    }
  }

  void redo() {
    if (state.canRedo) {
      state = state.copyWith(
          imagePath: state.history[state.historyIndex + 1],
          historyIndex: state.historyIndex + 1);
    }
  }

  void reset() {
    if (state.originalPath != null) loadImage(state.originalPath!);
  }

  void addText() {
    final list = [
      ...state.texts,
      EditorText(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: 'Your text')
    ];
    state = state.copyWith(texts: list, selectedTextIndex: list.length - 1);
  }

  void moveText(int index, Offset delta) {
    if (index < 0 || index >= state.texts.length) return;
    final list = [...state.texts];
    list[index] = list[index].copyWith(position: list[index].position + delta);
    state = state.copyWith(texts: list);
  }

  void selectText(int index) =>
      state = state.copyWith(selectedTextIndex: index);
  void updateText(int index, String text) {
    final list = [...state.texts];
    if (index >= 0 && index < list.length) {
      list[index] = list[index].copyWith(text: text);
      state = state.copyWith(texts: list);
    }
  }

  void removeText(int index) {
    final list = [...state.texts]..removeAt(index);
    state = state.copyWith(texts: list, clearSelection: true);
  }

  void toggleBefore() => state = state.copyWith(showBefore: !state.showBefore);
  void toggleLayers() => state = state.copyWith(showLayers: !state.showLayers);
  void pickBackground() {}
  void checkCompliance() {}
}

final editorProvider = StateNotifierProvider<EditorController, EditorState>(
    (_) => EditorController());
