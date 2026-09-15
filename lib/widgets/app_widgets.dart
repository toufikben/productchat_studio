import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../features/chat/chat_controller.dart';
import '../services/platform/connectivity_service.dart';

// ═══════════════════════════════════════════════════════════════
// AppIcons
// ═══════════════════════════════════════════════════════════════
class AppIcons {
  static Widget gradient(IconData icon,
          {double size = 44, double iconSize = 22, Color? color}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color ?? AppColors.primary,
              (color ?? AppColors.primary).withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      );

  static Widget outline(IconData icon, {double size = 40, Color? color}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(
            color: (color ?? AppColors.primary).withValues(alpha: 0.3),
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: size * 0.5),
      );

  static Widget circle(IconData icon, {double size = 56, Color? color}) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color ?? AppColors.primary,
              (color ?? AppColors.primary).withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      );
}

// ═══════════════════════════════════════════════════════════════
// GradientButton
// ═══════════════════════════════════════════════════════════════
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext c) => InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryGlow],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              else if (icon != null)
                Icon(icon, color: Colors.white),
              if (loading || icon != null) const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// ImagePreview
// ═══════════════════════════════════════════════════════════════
class ImagePreview extends StatelessWidget {
  final String path;
  final double? height;
  const ImagePreview({super.key, required this.path, this.height});

  @override
  Widget build(BuildContext c) => Container(
        height: height,
        child: InteractiveViewer(
          child: Center(
            child: Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// ActionChipWidget
// ═══════════════════════════════════════════════════════════════
class ActionChipWidget extends ConsumerWidget {
  final String label, op;
  final IconData? icon;
  const ActionChipWidget({
    super.key,
    required this.label,
    required this.op,
    this.icon,
  });

  @override
  Widget build(BuildContext c, WidgetRef r) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: icon != null
              ? Icon(icon, size: 16, color: AppColors.primary)
              : null,
          label: Text(label),
          backgroundColor: AppColors.surfaceAlt,
          side: const BorderSide(color: AppColors.border),
          labelStyle:
              const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          onPressed: () {
            if (op == 'recipes') {
              c.push('/recipes');
              return;
            }
            if (op == 'compliance') {
              c.push('/compliance');
              return;
            }
            r.read(chatProvider.notifier).submit(op);
          },
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// CreditsPill
// ═══════════════════════════════════════════════════════════════
class CreditsPill extends ConsumerWidget {
  const CreditsPill({super.key});

  @override
  Widget build(BuildContext c, WidgetRef r) {
    final credits = r.watch(chatProvider).credits;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => c.push('/paywall'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 16, color: AppColors.warning),
              const SizedBox(width: 4),
              Text('$credits',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EmptyState
// ═══════════════════════════════════════════════════════════════
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcons.circle(icon, size: 88),
              const SizedBox(height: 24),
              Text(title,
                  style: Theme.of(c).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: Theme.of(c).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// BeforeAfterSlider
// ═══════════════════════════════════════════════════════════════
class BeforeAfterSlider extends StatefulWidget {
  final String beforePath, afterPath;
  const BeforeAfterSlider({
    super.key,
    required this.beforePath,
    required this.afterPath,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.5;

  @override
  Widget build(BuildContext c) => LayoutBuilder(
        builder: (c, box) => GestureDetector(
          onHorizontalDragUpdate: (d) => setState(() => _position =
              (_position + d.delta.dx / box.maxWidth).clamp(0.0, 1.0)),
          child: Stack(
            children: [
              Positioned.fill(
                  child:
                      Image.file(File(widget.afterPath), fit: BoxFit.contain)),
              Positioned.fill(
                child: ClipRect(
                  clipper: _LeftClipper(_position),
                  child:
                      Image.file(File(widget.beforePath), fit: BoxFit.contain),
                ),
              ),
              Positioned(
                left: box.maxWidth * _position - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: AppColors.primary),
              ),
              Positioned(
                left: box.maxWidth * _position - 20,
                top: box.maxHeight / 2 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.drag_indicator, color: Colors.white),
                ),
              ),
              Positioned(left: 12, top: 12, child: _label('Before')),
              Positioned(right: 12, top: 12, child: _label('After')),
            ],
          ),
        ),
      );

  Widget _label(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(12)),
        child:
            Text(t, style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
}

class _LeftClipper extends CustomClipper<Rect> {
  final double position;
  _LeftClipper(this.position);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * position, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper old) => old.position != position;
}

// ═══════════════════════════════════════════════════════════════
// ShareButton
// ═══════════════════════════════════════════════════════════════
class ShareButton extends StatelessWidget {
  final String imagePath;
  final String? text;
  const ShareButton({super.key, required this.imagePath, this.text});

  Future<void> _share() async {
    final file = File(imagePath);
    if (!await file.exists()) return;
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: text ?? 'Made with ProductChat Studio ✨',
    );
  }

  @override
  Widget build(BuildContext c) => IconButton(
        icon: const Icon(Icons.share_outlined),
        onPressed: _share,
      );
}

// ═══════════════════════════════════════════════════════════════
// OfflineBanner
// ═══════════════════════════════════════════════════════════════
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext c, WidgetRef r) {
    final online = r.watch(connectivityProvider).valueOrNull ?? true;
    if (online) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withValues(alpha: 0.15),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: AppColors.warning, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No internet — some features disabled',
              style: TextStyle(color: AppColors.warning, fontSize: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ═══════════════════════════════════════════════════════════════
// ProgressBar
// ═══════════════════════════════════════════════════════════════
class ProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext c) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor: AppColors.surfaceAlt,
          valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                  color: destructive ? AppColors.danger : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
