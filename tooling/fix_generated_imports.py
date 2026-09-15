from pathlib import Path
root = Path('/home/ubuntu/productchat_studio')
imports = {
'lib/services/voice_search_service.dart': "import '../models/edit_request.dart';\n",
'lib/services/voice_presets_service.dart': "import 'package:hive_flutter/hive_flutter.dart';\n",
'lib/features/settings/voice_settings_screen.dart': "import 'package:flutter/material.dart';\n",
'lib/features/settings/voice_presets_screen.dart': "import 'package:flutter/material.dart';\n",
'lib/features/chat/voice_search_screen.dart': "import 'dart:io';\n",
'lib/services/free_quota_service.dart': "",
'lib/services/promo_code_service.dart': "import 'package:hive_flutter/hive_flutter.dart';\n",
'lib/services/trial_service.dart': "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
'lib/services/refund_service.dart': "import 'package:hive_flutter/hive_flutter.dart';\n",
'lib/services/payment_history_service.dart': "import 'package:hive_flutter/hive_flutter.dart';\n",
'lib/features/billing/subscription_status_screen.dart': "import 'package:flutter/material.dart';\n",
'lib/features/billing/promo_code_screen.dart': "import 'package:flutter/material.dart';\n",
'lib/features/billing/refund_policy_screen.dart': "import 'package:flutter/material.dart';\n",
}
for rel, imp in imports.items():
    if not imp: continue
    p=root/rel; text=p.read_text()
    if not text.startswith(imp): p.write_text(imp+text)
