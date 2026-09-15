import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../services/brand_service.dart';

final brandServiceProvider = Provider<BrandService>((_) => BrandService());

class BrandScreen extends ConsumerStatefulWidget {
  const BrandScreen({super.key});
  @override
  ConsumerState<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends ConsumerState<BrandScreen> {
  late BrandProfile _profile;
  bool _dirty = false;
  static const _colors = ['#6C5CE7','#00D2A8','#FFB547','#FF5C5C','#3B82F6','#EC4899','#8B5CF6','#14B8A6'];
  static const _fonts = ['Inter','Cairo','Tajawal','Poppins','Montserrat','Roboto'];
  @override void initState() { super.initState(); _profile = ref.read(brandServiceProvider).load(); }
  Color _hex(String h) => Color(int.parse('0xFF${h.replaceFirst('#','')}'));
  Future<void> _pickLogo() async { final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90); if (x != null) setState(() { _profile = _profile.copyWith(logoPath: x.path); _dirty = true; }); }
  Future<void> _save() async { await ref.read(brandServiceProvider).save(_profile); if (mounted) { setState(() => _dirty = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand saved'), backgroundColor: AppColors.success)); } }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Brand Identity'), actions: [if (_dirty) TextButton(onPressed: _save, child: const Text('Save'))]), body: ListView(padding: const EdgeInsets.all(16), children: [_logo(), const SizedBox(height: 20), _colorsRow('Primary Color', _profile.primaryColor, (v) => setState(() { _profile = _profile.copyWith(primaryColor: v); _dirty = true; })), const SizedBox(height: 18), _colorsRow('Secondary Color', _profile.secondaryColor, (v) => setState(() { _profile = _profile.copyWith(secondaryColor: v); _dirty = true; })), const SizedBox(height: 18), const Text('Font Family'), ..._fonts.map((f) => RadioListTile<String>(value: f, groupValue: _profile.fontFamily, title: Text(f), onChanged: (v) => setState(() { _profile = _profile.copyWith(fontFamily: v); _dirty = true; }))), TextField(decoration: const InputDecoration(labelText: 'Tagline (optional)'), onChanged: (v) { _profile = _profile.copyWith(tagline: v.isEmpty ? null : v); _dirty = true; }), SwitchListTile(title: const Text('Show watermark'), value: _profile.showWatermark, onChanged: (v) => setState(() { _profile = _profile.copyWith(showWatermark: v); _dirty = true; }))]));
  Widget _logo() => Row(children: [Container(width: 72,height:72, decoration: BoxDecoration(color: AppColors.surfaceAlt,borderRadius: BorderRadius.circular(14)), child: _profile.logoPath != null && File(_profile.logoPath!).existsSync() ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_profile.logoPath!),fit: BoxFit.cover)) : const Icon(Icons.business,color: AppColors.textTertiary)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Your Logo'), const SizedBox(height: 8), FilledButton.tonalIcon(onPressed: _pickLogo, icon: const Icon(Icons.upload), label: const Text('Upload'))]))]);
  Widget _colorsRow(String title, String selected, ValueChanged<String> onSelect) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), const SizedBox(height: 8), Wrap(spacing: 8, children: _colors.map((c) => GestureDetector(onTap: () => onSelect(c), child: Container(width: 40,height:40, decoration: BoxDecoration(color: _hex(c),shape: BoxShape.circle,border: Border.all(color: c == selected ? Colors.white : Colors.transparent,width: 3))))).toList())]);
}
