import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../services/ai_description_service.dart';
import '../../widgets/app_widgets.dart';

final aiDescriptionProvider = Provider((_) => AIDescriptionService());

class AIDescriptionScreen extends ConsumerStatefulWidget {
  final String imagePath;
  const AIDescriptionScreen({super.key, required this.imagePath});

  @override
  ConsumerState<AIDescriptionScreen> createState() => _S();
}

class _S extends ConsumerState<AIDescriptionScreen> {
  ProductDescription? _result;
  bool _loading = false;
  String? _error;
  String _language = 'ar';
  String _tone = 'professional';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref.read(aiDescriptionProvider).generate(
            widget.imagePath,
            language: _language,
            tone: _tone,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Description'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildResult(),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: 'Title',
          content: r.title,
          onCopy: () => _copy(r.title),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Description',
          content: r.description,
          onCopy: () => _copy(r.description),
        ),
        const SizedBox(height: 16),
        _TagsSection(tags: r.tags),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _language = _language == 'ar' ? 'en' : 'ar'),
                icon: const Icon(Icons.language),
                label: Text(_language == 'ar' ? 'Switch to English' : 'التبديل للعربية'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSuccessSnack(context, 'Copied');
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onCopy;
  const _Section({
    required this.title,
    required this.content,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onCopy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SelectableText(content, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
}

class _TagsSection extends StatelessWidget {
  final List<String> tags;
  const _TagsSection({required this.tags});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tags',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((t) => Chip(
                    label: Text(t),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(color: AppColors.primary),
                  )).toList(),
            ),
          ],
        ),
      );
}
