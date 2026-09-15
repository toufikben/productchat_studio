import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class MaskPainterScreen extends StatefulWidget {
  final String imagePath;
  const MaskPainterScreen({super.key, required this.imagePath});

  @override
  State<MaskPainterScreen> createState() => _MaskPainterScreenState();
}

class _MaskPainterScreenState extends State<MaskPainterScreen> {
  final _strokes = <List<Offset>>[];
  List<Offset>? _currentStroke;
  double _brushSize = 40.0;
  Size _canvasSize = Size.zero;

  void _start(Offset p) => setState(() => _currentStroke = [p]);
  void _update(Offset p) => setState(() => _currentStroke?.add(p));
  void _end() {
    if (_currentStroke != null && _currentStroke!.isNotEmpty) {
      _strokes.add(_currentStroke!);
    }
    _currentStroke = null;
    setState(() {});
  }

  void _clear() => setState(() {
        _strokes.clear();
        _currentStroke = null;
      });

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  Future<Uint8List?> _exportMask() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height),
      Paint()..color = Colors.black,
    );

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = _brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      _canvasSize.width.toInt(),
      _canvasSize.height.toInt(),
    );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _saveAndReturn() async {
    final bytes = await _exportMask();
    if (!mounted) return;
    Navigator.pop(context, bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Mask'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _strokes.isNotEmpty ? _clear : null,
          ),
          TextButton(
            onPressed: _strokes.isEmpty ? null : _saveAndReturn,
            child: const Text('Apply'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanStart: (d) => _start(d.localPosition),
                  onPanUpdate: (d) => _update(d.localPosition),
                  onPanEnd: (_) => _end(),
                  child: Container(
                    color: AppColors.bg,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MaskPainter(
                              strokes: _strokes,
                              current: _currentStroke,
                              brushSize: _brushSize,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.brush, color: AppColors.primary),
                Expanded(
                  child: Slider(
                    value: _brushSize,
                    min: 10,
                    max: 100,
                    onChanged: (v) => setState(() => _brushSize = v),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text('${_brushSize.toInt()}px',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset>? current;
  final double brushSize;

  _MaskPainter({
    required this.strokes,
    required this.current,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.isEmpty) return;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) drawStroke(s);
    if (current != null) drawStroke(current!);
  }

  @override
  bool shouldRepaint(covariant _MaskPainter old) => true;
}
