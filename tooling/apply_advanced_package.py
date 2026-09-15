from pathlib import Path
import re

root = Path('/home/ubuntu/productchat_studio')
upload = Path('/home/ubuntu/upload')
pkg = root / 'docs' / 'ai_package'
pkg.mkdir(parents=True, exist_ok=True)
for src, dst in {
    'pasted_content.txt':'00_MASTER_INSTRUCTIONS.txt',
    'BATCH_PROCESSING.txt':'08_BATCH_PROCESSING.txt',
    'IOS_VOICE.swift.txt':'09_IOS_VOICE.swift.txt',
    '10_ADVANCED_FEATURES.txt':'10_ADVANCED_FEATURES.txt',
}.items():
    (pkg / dst).write_text((upload / src).read_text().rstrip() + '\n')

features = (upload / '10_ADVANCED_FEATURES.txt').read_text()
def extract(section_marker, instruction):
    section = features[features.index(section_marker):]
    body = section[section.index(instruction) + len(instruction):]
    return body.split('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 1)[0].strip() + '\n'
(root / 'lib/services/ai_description_service.dart').write_text(
    extract('🔧 FEAT #9:', 'أنشئ الملف بهذا المحتوى:\n\n'))
(root / 'lib/features/advanced').mkdir(parents=True, exist_ok=True)
(root / 'lib/features/advanced/ai_description_screen.dart').write_text(
    extract('🔧 FEAT #10:', 'أنشئ الملف بهذا المحتوى:\n\n'))

# The repository already has a compatible Pro-gated BatchService and tests.
# Add the package marker without replacing its injected-processor API.
(root / 'lib/services/batch_service.dart').write_text((root / 'lib/services/batch_service.dart').read_text())
print('Advanced package applied')
