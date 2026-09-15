from pathlib import Path
root = Path('/home/ubuntu/productchat_studio')
text = Path('/home/ubuntu/upload/BILLING_COMPLETE.txt').read_text()
pkg = root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'21_BILLING_COMPLETE.txt').write_text(text.rstrip()+'\n')

def block(n):
    start = text.index(f'🔧 FIX #{n}:')
    nxt = text.find('🔧 FIX #', start + 10)
    return text[start:nxt if nxt >= 0 else len(text)]

def extract(n, marker):
    b = block(n); pos = b.find(marker)
    if pos < 0: raise RuntimeError(f'marker missing {n}')
    out = b[pos+len(marker):]
    out = out.split('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',1)[0]
    return out.strip()+'\n'

files = {
 55: ('lib/services/free_quota_service.dart', "import 'package:flutter_riverpod/flutter_riverpod.dart';"),
 56: ('lib/services/promo_code_service.dart', "import 'package:hive_flutter/hive_flutter.dart';"),
 57: ('lib/services/trial_service.dart', "import 'package:flutter_riverpod/flutter_riverpod.dart';"),
 58: ('lib/services/refund_service.dart', "import 'package:hive_flutter/hive_flutter.dart';"),
 59: ('lib/services/payment_history_service.dart', "import 'package:hive_flutter/hive_flutter.dart';"),
 60: ('lib/features/billing/subscription_status_screen.dart', "import 'package:flutter/material.dart';"),
 61: ('lib/features/billing/promo_code_screen.dart', "import 'package:flutter/material.dart';"),
 62: ('lib/features/billing/refund_policy_screen.dart', "import 'package:flutter/material.dart';"),
}
for n, (rel, marker) in files.items():
    target=root/rel; target.parent.mkdir(parents=True, exist_ok=True); target.write_text(extract(n, marker))
print('Billing FIX #55-#62 applied')
