from pathlib import Path
root=Path('/home/ubuntu/productchat_studio')
source=Path('/home/ubuntu/upload/27_NEW_FEATURES_part2.txt').read_text()
(root/'docs/ai_package/27_NEW_FEATURES_PART2.txt').write_text(source.rstrip()+'\n')
def block(n):
    start=source.index(f'🔧 FIX #{n}:'); nxt=source.find('🔧 FIX #', start+10)
    return source[start:nxt if nxt >= 0 else len(source)]
def dart(n):
    b=block(n)
    starts=[b.find(x) for x in ('import ', 'class ', 'enum ', 'const k')]
    start=min(v for v in starts if v >= 0)
    end=b.find('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', start)
    if end < 0: end=len(b)
    return b[start:end].strip()+'\n'
files={
 134:'lib/services/exif_service.dart',
 135:'lib/services/watermark_preset_service.dart',
 136:'lib/services/export_preset_service.dart',
 137:'lib/features/settings/onboarding_tips_screen.dart',
 138:'lib/services/rating_prompt_service.dart',
 139:'lib/widgets/rating_prompt_dialog.dart',
 140:'lib/features/history/timeline_screen.dart',
}
for n,rel in files.items():
    p=root/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(dart(n))
print('New features FIX #134-#140 applied')
