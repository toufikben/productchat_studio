import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants.dart';
import '../../models/edit_request.dart';
import '../../services/billing_service.dart';
import '../../services/permission_service.dart';
import '../../services/smart_analysis_service.dart';
import 'chat_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _picker = ImagePicker();
  final _analysis = SmartAnalysisService();
  String? _imagePath;
  String? _error;
  bool _busy = false;
  AnalysisResult? _analysisResult;

  @override
  void initState() {
    super.initState();
    // Listen to billing changes so the tier card updates without a rebuild.
    billingService.addListener(_onBillingChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PermissionService.requestInitialPermissions(context);
    });
  }

  @override
  void dispose() {
    billingService.removeListener(_onBillingChanged);
    super.dispose();
  }

  void _onBillingChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    setState(() {
      _error = null;
      _analysisResult = null;
    });
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 95,
      );
      if (!mounted || image == null) return;
      setState(() => _imagePath = image.path);
      // Run smart analysis automatically after image selection.
      _runAnalysis(image.path);
    } catch (error) {
      if (mounted) setState(() => _error = 'Unable to select image: $error');
    }
  }

  Future<void> _runAnalysis(String path) async {
    final result = await _analysis.analyze(path);
    if (!mounted) return;
    setState(() => _analysisResult = result);
  }

  Future<void> _runPatchMatch() async {
    final image = _imagePath;
    if (image == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ChatController(imagePath: image).dispatch(
      const EditRequest(op: EditOp.removeBg),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.ok && result.outputPath != null) {
        _imagePath = result.outputPath;
        _analysisResult = null;
      } else {
        _error = result.error ?? 'PatchMatch failed.';
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('ProductChat Studio'),
          actions: [
            IconButton(
              onPressed: () => context.push('/settings'),
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _imagePath == null
                      ? const Center(
                          child: Text(
                              'Select a product image to begin Smart Analysis'))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(File(_imagePath!),
                              fit: BoxFit.contain),
                        ),
                ),
                // Smart analysis suggestions banner.
                if (_analysisResult != null &&
                    _analysisResult!.ok &&
                    _analysisResult!.suggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Smart suggestions',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            for (final s in _analysisResult!.suggestions)
                              Text('• ${s.title}: ${s.description}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: Icon(
                      billingService.proService.isPro
                          ? Icons.verified_outlined
                          : Icons.photo_outlined,
                    ),
                    title: Text(
                      billingService.proService.isPro
                          ? 'Pro enabled'
                          : 'Free tier',
                    ),
                    subtitle: Text(
                      billingService.proService.isPro
                          ? 'All available local operations are enabled.'
                          : 'PatchMatch only \u2022 watermark enabled',
                    ),
                    trailing: billingService.proService.isPro
                        ? null
                        : Text(
                            '${billingService.freeQuota.remaining}/${AppConstants.freeMonthlyQuota}',
                          ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                Semantics(
                  button: true,
                  label: _imagePath == null
                      ? 'Select product image'
                      : 'Change image',
                  child: FilledButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(_imagePath == null
                        ? 'Select product image'
                        : 'Change image'),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Run local PatchMatch background removal',
                  child: FilledButton.tonalIcon(
                    onPressed:
                        _imagePath == null || _busy ? null : _runPatchMatch,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: const Text('Remove background (PatchMatch)'),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Open editor',
                  child: FilledButton(
                    onPressed: _imagePath == null
                        ? null
                        : () => context.push(
                            '/editor?imagePath=\${Uri.encodeComponent(_imagePath!)}'),
                    child: const Text('Open editor'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
