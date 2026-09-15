from pathlib import Path
import json
import re

root = Path('/home/ubuntu/productchat_studio')

# Preserve the supplied package in the repository for reproducibility.
upload = Path('/home/ubuntu/upload')
pkg = root / 'docs' / 'ai_package'
pkg.mkdir(parents=True, exist_ok=True)
source_map = {
    'read_first.txt': '00_READ_FIRST.txt',
    'all_fixes.txt': '01_ALL_FIXES.txt',
    'new_features.txt': '02_NEW_FEATURES.txt',
    'ROUTER_UPDATE.txt': '04_ROUTER_UPDATE.txt',
    'TESTS.txt': '05_TESTS.txt',
    'L10N.txt': '06_L10N.txt',
    'VERIFY.txt': '07_VERIFY.txt',
}
for src, dst in source_map.items():
    text = (upload / src).read_text().rstrip() + '\n'
    (pkg / dst).write_text(text)

# Extract the four test files from TESTS.txt exactly between their content fences.
tests = (upload / 'TESTS.txt').read_text()
sections = [
    ('test/services/voice_service_test.dart', '🧪 TEST #1:', '🧪 TEST #2:'),
    ('test/services/model_center_test.dart', '🧪 TEST #2:', '🧪 TEST #3:'),
    ('test/core/feature_flags_test.dart', '🧪 TEST #3:', '🧪 TEST #4:'),
    ('test/widgets/floating_nav_bar_test.dart', '🧪 TEST #4:', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n✅ نهاية الملف 05_TESTS.txt'),
]
for path, start_marker, end_marker in sections:
    section = tests[tests.index(start_marker):]
    section = section[:section.index(end_marker)]
    content = section[section.index('أنشئ الملف بهذا المحتوى:') + len('أنشئ الملف بهذا المحتوى:'):]
    content = content.split('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 1)[0]
    content = content.strip('\n') + '\n'
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content)

# Add the required localization keys while preserving existing entries.
keys_en = {
    'navHome':'Home','navChat':'Chat','navEditor':'Editor','navBatch':'Batch','navSettings':'Settings',
    'homeWelcome':'Welcome','homeQuickActions':'Quick Actions','homeRecent':'Recent','homeSeeAll':'See all',
    'homeRemoveBg':'Remove BG','homeEnhance':'Enhance','homeShadow':'Shadow','voiceTitle':'Voice Commands',
    'voiceStart':'Start listening','voiceStop':'Stop listening','voiceSpeak':'Speak','voiceStopSpeak':'Stop speaking',
    'voiceListening':'Listening...','voiceError':'Voice error','modelsTitle':'AI Models','modelsReadyCount':'{ready} of {total} ready',
    'modelsDownloadHint':'Download only what you need','modelsDownload':'Download','modelsCancel':'Cancel','modelsDelete':'Delete',
    'modelsReady':'Ready','modelsFailed':'Failed','modelsDownloading':'Downloading...','modelsVerifying':'Verifying...',
    'maskPainterTitle':'Draw Mask','maskPainterApply':'Apply','maskPainterClear':'Clear','maskPainterUndo':'Undo',
    'maskPainterBrushSize':'Brush Size','chatStudioTitle':'Chat Studio','chatStudioWelcome':'Welcome! Upload an image and type your command.',
    'chatStudioType':'Type your command...','featureNotReady':'This feature is under development','modelNotDownloaded':'Model not downloaded. Go to Settings > Models.',
}
keys_ar = {
    'navHome':'الرئيسية','navChat':'المحادثة','navEditor':'المحرر','navBatch':'الدفعات','navSettings':'الإعدادات',
    'homeWelcome':'مرحباً','homeQuickActions':'إجراءات سريعة','homeRecent':'الأحدث','homeSeeAll':'عرض الكل',
    'homeRemoveBg':'إزالة خلفية','homeEnhance':'تحسين','homeShadow':'ظل','voiceTitle':'الأوامر الصوتية',
    'voiceStart':'بدء الاستماع','voiceStop':'إيقاف الاستماع','voiceSpeak':'تحدث','voiceStopSpeak':'إيقاف التحدث',
    'voiceListening':'جارٍ الاستماع...','voiceError':'خطأ صوتي','modelsTitle':'نماذج AI','modelsReadyCount':'{ready} من {total} جاهز',
    'modelsDownloadHint':'حمّل ما تحتاجه فقط','modelsDownload':'تحميل','modelsCancel':'إلغاء','modelsDelete':'حذف',
    'modelsReady':'جاهز','modelsFailed':'فشل','modelsDownloading':'جارٍ التحميل...','modelsVerifying':'جارٍ التحقق...',
    'maskPainterTitle':'رسم قناع','maskPainterApply':'تطبيق','maskPainterClear':'مسح','maskPainterUndo':'تراجع',
    'maskPainterBrushSize':'حجم الفرشاة','chatStudioTitle':'استوديو المحادثة','chatStudioWelcome':'مرحباً! ارفع صورة واكتب أمرك.',
    'chatStudioType':'اكتب أمرك...','featureNotReady':'هذه الميزة قيد التطوير','modelNotDownloaded':'النموذج غير محمّل. اذهب إلى الإعدادات > النماذج.',
}
for locale, additions in [('en', keys_en), ('ar', keys_ar)]:
    path = root / 'lib' / 'l10n' / f'app_{locale}.arb'
    data = json.loads(path.read_text())
    data.update(additions)
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n')

(root / 'l10n.yaml').write_text('''arb-dir: lib/l10n\ntemplate-arb-file: app_en.arb\noutput-localization-file: app_localizations.dart\noutput-class: AppLocalizations\nnullable-getter: false\n''')
print('Package updates applied')
