from pathlib import Path
import shutil
root = Path('/home/ubuntu/productchat_studio')
text = Path('/home/ubuntu/upload/CONFIG_COMPLETE.txt').read_text()
pkg = root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'23_CONFIG_COMPLETE.txt').write_text(text.rstrip()+'\n')

def block(n):
    start = text.index(f'🔧 FIX #{n}:')
    nxt = text.find('🔧 FIX #', start + 10)
    return text[start:nxt if nxt >= 0 else len(text)]

def extract(n, marker):
    b=block(n); pos=b.find(marker)
    if pos < 0: raise RuntimeError(f'marker missing {n}')
    out=b[pos+len(marker):]
    out=out.split('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',1)[0]
    return out.strip()+'\n'
for n, rel, marker in [
 (84,'analysis_options.yaml','include: package:flutter_lints/flutter.yaml'),
 (85,'vercel.json','{\n  "$schema"'),
 (86,'web/index.html','<!DOCTYPE html>'),
 (87,'web/manifest.json','{\n  "name": "ProductChat Studio"'),
 (88,'web/flutter_bootstrap.js','{{flutter_js}}'),
 (91,'.gitignore','# Flutter'),
]:
    p=root/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(extract(n, marker))
# FIX #89: prefer requested source, then use the repository's final store icon.
src=root/'assets/icons/app_icon.png'
if not src.exists(): src=root/'store_assets/app_icon_512_final.png'
if not src.exists(): raise FileNotFoundError('No PNG source available for web/favicon.png')
(root/'web/favicon.png').write_bytes(src.read_bytes())
print('Config FIX #84-#89 and #91 applied')
