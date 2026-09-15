from pathlib import Path
root=Path('/home/ubuntu/productchat_studio')
source=Path('/home/ubuntu/upload/27_NEW_FEATURES_part1.txt').read_text()
pkg=root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'27_NEW_FEATURES_PART1.txt').write_text(source.rstrip()+'\n')
def block(n):
    start=source.index(f'🔧 FIX #{n}:'); nxt=source.find('🔧 FIX #', start+10)
    return source[start:nxt if nxt >= 0 else len(source)]
def dart(n):
    b=block(n); marker='\n'; start=b.find(marker)+1
    # first source content follows the separator line; find the first import/class declaration
    candidates=[b.find(x) for x in ('import ', 'class ', 'enum ')]
    start=min(v for v in candidates if v >= 0)
    end=b.find('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', start)
    if end < 0: end=len(b)
    return b[start:end].strip()+'\n'
files={
 123:'lib/services/crop_rotate_service.dart',
 124:'lib/services/filters_service.dart',
 125:'lib/services/background_blur_service.dart',
 126:'lib/services/zip_export_service.dart',
 127:'lib/services/auto_save_service.dart',
 128:'lib/services/enhancement_presets_service.dart',
 129:'lib/features/editor/filters_screen.dart',
 130:'lib/features/editor/compare_screen.dart',
}
for n,rel in files.items():
    p=root/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(dart(n))
print('New features FIX #123-#130 applied')
