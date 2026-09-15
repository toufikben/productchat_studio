import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/crash_reporting_service.dart';
import 'app_widgets.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? fallback;
  const ErrorBoundary({super.key, required this.child, this.fallback});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    ErrorWidget.builder = (details) {
      _logError(details.exception, details.stack);
      return widget.fallback ?? _buildFallback(details.exception, details.stack);
    };
  }

  void _logError(Object error, StackTrace? stack) {
    CrashReportingService.recordError(error, stack, context: 'widget');
    if (mounted) setState(() { _error = error; _stackTrace = stack; });
  }

  Widget _buildFallback(Object? error, StackTrace? stack) => Material(
    color: AppColors.bg,
    child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AppIcons.circle(Icons.error_outline, size: 88, color: AppColors.danger),
        const SizedBox(height: 24),
        Text('Something went wrong', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('We recorded the error. You can try again or restart the app.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          OutlinedButton.icon(onPressed: () => setState(() { _error = null; _stackTrace = null; }), icon: const Icon(Icons.refresh), label: const Text('Retry')),
          if (kDebugMode) ...[
            const SizedBox(width: 12),
            FilledButton.icon(onPressed: () => _showDetails(error, stack), icon: const Icon(Icons.bug_report), label: const Text('Details')),
          ],
        ]),
      ]),
    )),
  );

  void _showDetails(Object? error, StackTrace? stack) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Error Details'),
      content: SingleChildScrollView(child: SelectableText('${error ?? "Unknown"}\n\n${stack ?? "No stack trace"}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace'))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );

  @override
  Widget build(BuildContext context) => _error == null ? widget.child : _buildFallback(_error, _stackTrace);
}
