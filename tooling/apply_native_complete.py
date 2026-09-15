from pathlib import Path
root = Path('/home/ubuntu/productchat_studio')
text = Path('/home/ubuntu/upload/NATIVE_COMPLETE.txt').read_text()
pkg = root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'22_NATIVE_COMPLETE.txt').write_text(text.rstrip()+'\n')

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

items = {
 68: ('android/app/src/main/kotlin/com/productchat/studio/native/SeikaChannel.kt', 'package com.productchat.studio.native'),
 69: ('android/app/src/main/kotlin/com/productchat/studio/native/HomeWidgetProvider.kt', 'package com.productchat.studio.native'),
 70: ('android/app/src/main/res/layout/widget_productchat.xml', '<?xml version="1.0" encoding="utf-8"?>'),
 71: ('android/app/src/main/res/drawable/widget_bg.xml', '<?xml version="1.0" encoding="utf-8"?>'),
 72: ('android/app/src/main/res/xml/widget_info.xml', '<?xml version="1.0" encoding="utf-8"?>'),
 73: ('android/app/src/main/kotlin/com/productchat/studio/native/BatchForegroundService.kt', 'package com.productchat.studio.native'),
 75: ('android/app/src/main/kotlin/com/productchat/studio/native/ShareReceiver.kt', 'package com.productchat.studio.native'),
 77: ('lib/services/share_receiver_service.dart', "import 'package:flutter/services.dart';"),
 78: ('ios/Runner/Channels/SeikaChannel.swift', 'import Flutter'),
 79: ('ios/Runner/Channels/ShareReceiver.swift', 'import Flutter'),
 83: ('android/app/proguard-rules.pro', '# ONNX Runtime — keep native bindings'),
}
for n,(rel,marker) in items.items():
    p=root/rel; p.parent.mkdir(parents=True, exist_ok=True)
    value = extract(n, marker)
    if n in (68, 69, 73, 75):
        value = 'package com.productchat.studio.native\n\n' + value
    p.write_text(value)
print('Native FIX #68-#83 source files applied')
