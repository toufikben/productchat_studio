from pathlib import Path

root = Path('/home/ubuntu/productchat_studio')
part1 = Path('/home/ubuntu/upload/CORE_FEATURES.txt').read_text()
part2 = Path('/home/ubuntu/upload/CORE_FEATURES_part2.txt').read_text()
(pkg := root/'docs'/'ai_package').mkdir(parents=True, exist_ok=True)
(pkg/'18_CORE_FEATURES.txt').write_text(part1.rstrip()+'\n')
(pkg/'18_CORE_FEATURES_PART2.txt').write_text(part2.rstrip()+'\n')

def section(text, number, start_marker):
    marker = f'🔧 FIX #{number}:'
    start = text.index(marker)
    next_fix = text.find('🔧 FIX #', start + len(marker))
    end = next_fix if next_fix >= 0 else len(text)
    block = text[start:end]
    # Start after the content instruction marker, preserving the supplied code.
    pos = block.find(start_marker)
    if pos < 0:
        raise RuntimeError(f'missing start marker for FIX {number}')
    content = block[pos + len(start_marker):].strip('\n') + '\n'
    content = content.split('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 1)[0].rstrip() + '\n'
    return content

# Exact file destinations and content starts.
items = [
 (20, 'lib/core/constants.dart', 'استبدل الملف بالكامل بهذا:\n\n', part1),
 (21, 'lib/services/ai/migan_service.dart', 'import \'dart:io\';', part1),
 (22, 'lib/services/ai/qwen_edit_service.dart', 'import \'dart:io\';', part1),
 (23, 'lib/services/ai/relight_service.dart', 'import \'dart:io\';', part1),
 (24, 'lib/services/ai/colorize_service.dart', 'import \'dart:io\';', part1),
 (25, 'lib/services/product_fidelity_service.dart', 'import \'dart:io\';', part1),
 (26, 'lib/services/watermark_service.dart', 'import \'dart:io\';', part2),
 (27, 'lib/services/compliance_service.dart', 'import \'dart:io\';', part2),
 (28, 'lib/services/recipe_runner_service.dart', 'import \'../models/edit_request.dart\';', part2),
 (29, 'lib/services/ai_service.dart', '// ملاحظة: هذا الملف يجمع كل خدمات AI في مكان واحد.', part2),
 (30, 'lib/features/chat/chat_controller.dart', 'import \'package:flutter_riverpod/flutter_riverpod.dart\';', part2),
 (31, 'android/app/src/main/kotlin/com/productchat/studio/native/MIGanChannel.kt', 'package com.productchat.studio.native', part2),
 (32, 'android/app/src/main/kotlin/com/productchat/studio/native/QwenEditChannel.kt', 'package com.productchat.studio.native', part2),
 (33, 'android/app/src/main/kotlin/com/productchat/studio/MainActivity.kt', 'package com.productchat.studio', part2),
]
for number, rel, start_marker, source in items:
    content = section(source, number, start_marker)
    if number in (31, 32):
        content = 'package com.productchat.studio.native\n\n' + content
    elif number == 33:
        content = 'package com.productchat.studio\n\n' + content
    target = root/rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)

# Add elapsed duration without breaking existing EditResult call sites.
result = root/'lib/models/edit_result.dart'
result.write_text('''class EditResult {\n  final bool ok;\n  final String? outputPath;\n  final String? error;\n  final int creditsUsed;\n  final Duration? duration;\n\n  const EditResult({\n    required this.ok,\n    this.outputPath,\n    this.error,\n    this.creditsUsed = 0,\n    this.duration,\n  });\n\n  const EditResult.failure(String message)\n      : ok = false,\n        outputPath = null,\n        error = message,\n        creditsUsed = 0,\n        duration = null;\n}\n''')
print('FIX #20-#33 extracted and applied')
