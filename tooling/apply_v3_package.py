from pathlib import Path
import re

root = Path('/home/ubuntu/productchat_studio')
upload = Path('/home/ubuntu/upload')
pkg = root / 'docs' / 'ai_package'
pkg.mkdir(parents=True, exist_ok=True)
copy = {
  'pasted_content.txt':'11_MASTER_INSTRUCTIONS.txt',
  'BRAND_IDENTITY.txt':'12_BRAND_IDENTITY.txt',
  'SMART_ANALYSIS.txt':'13_SMART_ANALYSIS.txt',
  '14_AB_TESTING_REFERRAL.txt':'14_AB_TESTING_REFERRAL.txt',
  '15_ANALYTICS_DASHBOARD.txt':'15_ANALYTICS_DASHBOARD.txt',
  'ADVANCED_2026.txt':'16_ADVANCED_2026.txt',
}
for src, dst in copy.items():
  (pkg / dst).write_text((upload / src).read_text().rstrip() + '\n')


def between(text, marker, instruction):
  section = text[text.index(marker):]
  body = section[section.index(instruction)+len(instruction):]
  return body.split('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',1)[0].strip()+'\n'

brand = (upload/'BRAND_IDENTITY.txt').read_text()
(root/'lib/services/brand_service.dart').write_text(between(brand, '🔧 FEAT #11:', 'import \'dart:convert\';'))
# prepend the import marker removed by slicing logic
brand_service = (root/'lib/services/brand_service.dart').read_text()
(root/'lib/services/brand_service.dart').write_text("import 'dart:convert';\n" + brand_service)

smart = (upload/'SMART_ANALYSIS.txt').read_text()
(root/'lib/services/smart_analysis_service.dart').write_text(between(smart, '🔧 FEAT #13:', 'import \'dart:io\';'))
(root/'lib/services/smart_analysis_service.dart').write_text("import 'dart:io';\n" + (root/'lib/services/smart_analysis_service.dart').read_text())
(root/'lib/widgets/smart_analysis_panel.dart').write_text(between(smart, '🔧 FEAT #14:', 'import \'package:flutter/material.dart\';'))
(root/'lib/widgets/smart_analysis_panel.dart').write_text("import 'package:flutter/material.dart';\n" + (root/'lib/widgets/smart_analysis_panel.dart').read_text())

ab = (upload/'14_AB_TESTING_REFERRAL.txt').read_text()
(root/'lib/services/price_ab_test_service.dart').write_text(between(ab, '🔧 FEAT #15:', 'import \'dart:math\';'))
(root/'lib/services/price_ab_test_service.dart').write_text("import 'dart:math';\n" + (root/'lib/services/price_ab_test_service.dart').read_text())
(root/'lib/services/referral_service.dart').write_text(between(ab, '🔧 FEAT #16:', 'import \'dart:math\';'))
(root/'lib/services/referral_service.dart').write_text("import 'dart:math';\n" + (root/'lib/services/referral_service.dart').read_text())

adv = (upload/'ADVANCED_2026.txt').read_text()
(root/'lib/services/feature_roadmap_service.dart').write_text(between(adv, '🔧 FEAT #19:', '/// FeatureRoadmapService'))
(root/'lib/features/settings/roadmap_screen.dart').write_text(between(adv, '🔧 FEAT #20:', 'import \'package:flutter/material.dart\';'))
(root/'lib/features/settings/roadmap_screen.dart').write_text("import 'package:flutter/material.dart';\n" + (root/'lib/features/settings/roadmap_screen.dart').read_text())

# The supplied brand screen has a malformed nested State type. Write a compatible complete screen.
(root/'lib/features/settings/brand_screen.dart').write_text('''import 'dart:io';
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
''')

# Compatible analytics screen using the existing lightweight widgets API.
(root/'lib/features/settings/analytics_screen.dart').write_text('''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) => Scaffold(appBar: AppBar(title: const Text('Analytics')), body: ValueListenableBuilder(valueListenable: Hive.box('analytics').listenable(), builder: (_, box, __) { final counts = <String,int>{}; for (final raw in box.values) { if (raw is Map) { final e = raw['event'] as String? ?? 'unknown'; counts[e] = (counts[e] ?? 0) + 1; } } final entries = counts.entries.toList()..sort((a,b) => b.value.compareTo(a.value)); return ListView(padding: const EdgeInsets.all(16), children: [Row(children: [Expanded(child: _Stat('Total events','${box.length}',AppColors.primary)), const SizedBox(width: 12), Expanded(child: _Stat('Event types','${counts.length}',AppColors.success))]), const SizedBox(height: 24), ...entries.map((e) => Card(child: ListTile(title: Text(e.key), trailing: Text('${e.value}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))))]; }));
}
class _Stat extends StatelessWidget { final String label,value; final Color color; const _Stat(this.label,this.value,this.color); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface,borderRadius: BorderRadius.circular(16),border: Border.all(color: AppColors.border)), child: Column(children: [Text(value,style: TextStyle(color: color,fontSize: 24,fontWeight: FontWeight.bold)), Text(label,style: const TextStyle(color: AppColors.textSecondary,fontSize: 12))])); }
''')

# Referral screen compatible with the supplied service and standard StatefulWidget lifecycle.
(root/'lib/features/settings/referral_screen.dart').write_text('''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../services/referral_service.dart';
class ReferralScreen extends StatefulWidget { const ReferralScreen({super.key}); @override State<ReferralScreen> createState() => _ReferralScreenState(); }
class _ReferralScreenState extends State<ReferralScreen> { final _ctrl = TextEditingController(); late String _code; @override void initState(){super.initState();_code=ReferralService.getMyCode();} @override void dispose(){_ctrl.dispose();super.dispose();} @override Widget build(BuildContext context){ final count=ReferralService.getReferralCount(); return Scaffold(appBar: AppBar(title: const Text('Invite Friends')),body: ListView(padding: const EdgeInsets.all(16),children:[Container(padding: const EdgeInsets.all(24),decoration: BoxDecoration(gradient: const LinearGradient(colors:[AppColors.primary,AppColors.primaryGlow]),borderRadius: BorderRadius.circular(20)),child: Column(children:[const Text('Your personal code',style: TextStyle(color:Colors.white70)),Text(_code,style: const TextStyle(color:Colors.white,fontSize:28,fontWeight:FontWeight.bold,letterSpacing:4)),Row(mainAxisAlignment: MainAxisAlignment.center,children:[IconButton(onPressed:(){Clipboard.setData(ClipboardData(text:_code));},icon:const Icon(Icons.copy,color:Colors.white)),FilledButton.icon(onPressed:()=>Share.share('Try ProductChat Studio! ${ReferralService.inviteLink()}'),icon:const Icon(Icons.share),label:const Text('Share'))])])),const SizedBox(height:20),Text('Successful invites: $count'),const SizedBox(height:16),Row(children:[Expanded(child:TextField(controller:_ctrl,maxLength:8,decoration:const InputDecoration(hintText:'ABCD1234',counterText:''))),const SizedBox(width:8),FilledButton(onPressed:() async {final r=await ReferralService.applyCode(_ctrl.text);if(mounted){_ctrl.clear();ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(r.status)));setState((){});}},child:const Text('Apply'))]) ]));}}
''')
print('v3 package remaining files applied')
