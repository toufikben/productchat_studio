from pathlib import Path

root = Path('/home/ubuntu/productchat_studio')
text = Path('/home/ubuntu/upload/UI_SCREENS.txt').read_text()
pkg = root/'docs'/'ai_package'
pkg.mkdir(parents=True, exist_ok=True)
(pkg/'19_UI_SCREENS.txt').write_text(text.rstrip()+'\n')

def block(number):
    start = text.index(f'🔧 FIX #{number}:')
    nxt = text.find('🔧 FIX #', start + 10)
    return text[start:nxt if nxt >= 0 else len(text)]

def clean_code(raw):
    raw = raw.split('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 1)[0]
    return raw.rstrip()+'\n'

files = {
  34:'lib/features/settings/developer_screen.dart',
  35:'lib/features/settings/marketplace_screen.dart',
  36:'lib/features/settings/about_screen.dart',
  37:'lib/features/settings/feedback_screen.dart',
  38:'lib/features/settings/update_screen.dart',
  39:'lib/features/chat/chat_history_screen.dart',
  40:'lib/features/editor/presets_screen.dart',
  41:'lib/features/settings/favorites_screen.dart',
}
for number, rel in files.items():
    b = block(number)
    first = b.find('import ')
    if first < 0:
        raise RuntimeError(f'no Dart code for {number}')
    target = root/rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(clean_code(b[first:]))

# Replace router with the supplied complete route table.
b = block(42)
start = b.find('import ')
router = clean_code(b[start:])
(root/'lib/core/router.dart').write_text(router)
print('UI FIX #34-#42 applied')
