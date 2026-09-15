import 'package:flutter/material.dart';

class AppIcons {
  static const image = Icons.image;
  static Widget circle(IconData icon, {double size = 24, Color? color}) =>
      Icon(icon, size: size, color: color);
  static Widget outline(IconData icon, {double size = 24, Color? color}) =>
      Icon(icon, size: size, color: color);
}
class ImagePreview extends StatelessWidget { const ImagePreview({super.key}); @override Widget build(BuildContext context) => const SizedBox.shrink(); }
class ActionChipWidget extends StatelessWidget { final String label; const ActionChipWidget({super.key, required this.label}); @override Widget build(BuildContext context) => Chip(label: Text(label)); }
class CreditsPill extends StatelessWidget { const CreditsPill({super.key}); @override Widget build(BuildContext context) => const Chip(label: Text('3 credits')); }
class EmptyState extends StatelessWidget { const EmptyState({super.key}); @override Widget build(BuildContext context) => const Center(child: Text('Nothing here yet')); }
class GradientButton extends StatelessWidget { final String label; final VoidCallback? onPressed; const GradientButton({super.key, required this.label, this.onPressed}); @override Widget build(BuildContext context) => FilledButton(onPressed: onPressed, child: Text(label)); }
class BeforeAfterSlider extends StatelessWidget { const BeforeAfterSlider({super.key}); @override Widget build(BuildContext context) => const SizedBox.shrink(); }
class ShareButton extends StatelessWidget { const ShareButton({super.key}); @override Widget build(BuildContext context) => IconButton(onPressed: () {}, icon: const Icon(Icons.share)); }
class OfflineBanner extends StatelessWidget { const OfflineBanner({super.key}); @override Widget build(BuildContext context) => const Banner(message: 'Offline', location: BannerLocation.topEnd, child: SizedBox.shrink()); }
class UndoRedoBar extends StatelessWidget { const UndoRedoBar({super.key}); @override Widget build(BuildContext context) => Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.undo)), IconButton(onPressed: () {}, icon: const Icon(Icons.redo))]); }
class ModernCard extends StatelessWidget { final Widget child; const ModernCard({super.key, required this.child}); @override Widget build(BuildContext context) => Card(child: child); }
class StatCard extends StatelessWidget { const StatCard({super.key}); @override Widget build(BuildContext context) => const ModernCard(child: SizedBox(height: 40)); }
class ProgressBar extends StatelessWidget { final double value; const ProgressBar({super.key, this.value = .5}); @override Widget build(BuildContext context) => LinearProgressIndicator(value: value); }
class ShimmerLoader extends StatelessWidget { const ShimmerLoader({super.key}); @override Widget build(BuildContext context) => const CircularProgressIndicator(); }
Future<void> showConfirmDialog(BuildContext context, String title) async { await showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(title), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))])); }
void showSuccessSnack(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
void showErrorSnack(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
