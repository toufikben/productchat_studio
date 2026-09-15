from pathlib import Path
root = Path('/home/ubuntu/productchat_studio')
text = Path('/home/ubuntu/upload/20_VOICE_COMPLETE.txt').read_text()
pkg = root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'20_VOICE_COMPLETE.txt').write_text(text.rstrip()+'\n')

def block(n):
    start = text.index(f'🔧 FIX #{n}:')
    nxt = text.find('🔧 FIX #', start + 10)
    return text[start:nxt if nxt >= 0 else len(text)]

def code(n, marker):
    b = block(n); pos = b.find(marker)
    if pos < 0: raise RuntimeError(f'marker missing {n}')
    out = b[pos+len(marker):]
    out = out.split('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',1)[0]
    return out.strip()+'\n'

files = {
 45: ('lib/services/voice_service.dart', "استبدل الملف بالكامل بهذا:\n\n"),
 46: ('lib/services/voice_search_service.dart', "import '../models/edit_request.dart';"),
 47: ('lib/services/voice_presets_service.dart', "import 'package:hive_flutter/hive_flutter.dart';"),
 48: ('lib/features/settings/voice_settings_screen.dart', "import 'package:flutter/material.dart';"),
 49: ('lib/features/settings/voice_presets_screen.dart', "import 'package:flutter/material.dart';"),
 50: ('lib/features/chat/voice_search_screen.dart', "import 'dart:io';"),
}
for n, (rel, marker) in files.items():
    target = root/rel; target.parent.mkdir(parents=True, exist_ok=True); target.write_text(code(n, marker))
print('Voice FIX #45-#50 applied')
