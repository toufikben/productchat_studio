import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/filters_service.dart';
import '../../widgets/app_widgets.dart';

class FiltersScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const FiltersScreen({super.key, required this.imagePath});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  final _filters = FiltersService();
  FilterPreset _selected = FilterPreset.none;
  double _intensity = 1.0;
  String? _previewPath;
  bool _loading = false;

  Future<void> _applyPreview(FilterPreset preset) async {
    setState(() {
      _selected = preset;
      _loading = true;
    });
    final result = await _filters.apply(
      widget.imagePath,
      preset: preset,
      intensity: _intensity,
    );
    if (!mounted) return;
    setState(() {
      _previewPath = result.ok ? result.outputPath : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: _previewPath == null
                ? null
                : () => Navigator.pop(context, _previewPath),
            child: const Text('Apply'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Image.file(
                      File(_previewPath ?? widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (_loading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Intensity',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _intensity,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (v) => setState(() => _intensity = v),
                        onChangeEnd: (_) => _applyPreview(_selected),
                      ),
                    ),
                    Text('${(_intensity * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: FilterPreset.values.length,
                    itemBuilder: (_, i) {
                      final p = FilterPreset.values[i];
                      final selected = p == _selected;
                      return GestureDetector(
                        onTap: () => _applyPreview(p),
                        child: Container(
                          width: 70,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _label(p),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _label(FilterPreset p) {
    switch (p) {
      case FilterPreset.none: return 'None';
      case FilterPreset.vivid: return 'Vivid';
      case FilterPreset.vintage: return 'Vintage';
      case FilterPreset.mono: return 'Mono';
      case FilterPreset.sepia: return 'Sepia';
      case FilterPreset.cool: return 'Cool';
      case FilterPreset.warm: return 'Warm';
      case FilterPreset.dramatic: return 'Dramatic';
      case FilterPreset.fade: return 'Fade';
      case FilterPreset.blackWhite: return 'B&W';
      case FilterPreset.film: return 'Film';
      case FilterPreset.cinematic: return 'Cinema';
      case FilterPreset.matte: return 'Matte';
      case FilterPreset.sunny: return 'Sunny';
      case FilterPreset.cold: return 'Cold';
    }
  }
}
