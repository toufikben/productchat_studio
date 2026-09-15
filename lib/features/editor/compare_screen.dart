import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CompareScreen extends StatefulWidget {
  final String beforePath;
  final String afterPath;
  const CompareScreen({
    super.key,
    required this.beforePath,
    required this.afterPath,
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onHorizontalDragUpdate: (d) => setState(() {
              _position = (_position + d.delta.dx / constraints.maxWidth).clamp(0.0, 1.0);
            }),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(File(widget.afterPath), fit: BoxFit.contain),
                ),
                Positioned.fill(
                  child: ClipRect(
                    clipper: _LeftClipper(_position),
                    child: Image.file(File(widget.beforePath), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * _position - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: AppColors.primary),
                ),
                Positioned(
                  left: constraints.maxWidth * _position - 20,
                  top: constraints.maxHeight / 2 - 20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.drag_indicator, color: Colors.white),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _label('Before'),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _label('After'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
  );
}

class _LeftClipper extends CustomClipper<Rect> {
  final double position;
  _LeftClipper(this.position);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper old) => old.position != position;
}
