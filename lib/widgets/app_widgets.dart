import 'package:flutter/material.dart';
class AppIcons { static const image = Icons.image; }
class ImagePreview extends StatelessWidget { const ImagePreview({super.key}); @override Widget build(BuildContext c) => const SizedBox.shrink(); }
class ActionChipWidget extends StatelessWidget { final String label; const ActionChipWidget({super.key, required this.label}); @override Widget build(BuildContext c) => Chip(label: Text(label)); }
class CreditsPill extends StatelessWidget { const CreditsPill({super.key}); @override Widget build(BuildContext c) => const Chip(label: Text('3 credits')); }
class EmptyState extends StatelessWidget { const EmptyState({super.key}); @override Widget build(BuildContext c) => const Center(child: Text('Nothing here yet')); }
class GradientButton extends StatelessWidget { final String label; final VoidCallback? onPressed; const GradientButton({super.key, required this.label, this.onPressed}); @override Widget build(BuildContext c) => FilledButton(onPressed: onPressed, child: Text(label)); }
class BeforeAfterSlider extends StatelessWidget { const BeforeAfterSlider({super.key}); @override Widget build(BuildContext c) => const SizedBox.shrink(); }
class ShareButton extends StatelessWidget { const ShareButton({super.key}); @override Widget build(BuildContext c) => IconButton(onPressed: () {}, icon: const Icon(Icons.share)); }
class OfflineBanner extends StatelessWidget { const OfflineBanner({super.key}); @override Widget build(BuildContext c) => const Banner(message: 'Offline', location: BannerLocation.topEnd, child: SizedBox.shrink()); }
class UndoRedoBar extends StatelessWidget { const UndoRedoBar({super.key}); @override Widget build(BuildContext c) => Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.undo)), IconButton(onPressed: () {}, icon: const Icon(Icons.redo))]); }
class ModernCard extends StatelessWidget { final Widget child; const ModernCard({super.key, required this.child}); @override Widget build(BuildContext c) => Card(child: child); }
class StatCard extends StatelessWidget { const StatCard({super.key}); @override Widget build(BuildContext c) => const ModernCard(child: SizedBox(height: 40)); }
class ProgressBar extends StatelessWidget { final double value; const ProgressBar({super.key, this.value = .5}); @override Widget build(BuildContext c) => LinearProgressIndicator(value: value); }
class ShimmerLoader extends StatelessWidget { const ShimmerLoader({super.key}); @override Widget build(BuildContext c) => const CircularProgressIndicator(); }
Future<void> showConfirmDialog(BuildContext c, String title) async { await showDialog<void>(context: c, builder: (_) => AlertDialog(title: Text(title), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))])); }
void showSuccessSnack(BuildContext c, String message) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(message)));
void showErrorSnack(BuildContext c, String message) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(message)));
