from pathlib import Path
root = Path('/home/ubuntu/productchat_studio')
source = Path('/home/ubuntu/upload/24_L10N_COMPLETE.txt').read_text()
pkg = root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'24_L10N_COMPLETE_PART1.txt').write_text(source.rstrip()+'\n')

def block(n):
    start = source.index(f'🔧 FIX #{n}:')
    nxt = source.find('🔧 FIX #', start + 10)
    return source[start:nxt if nxt >= 0 else len(source)]

def arb(n):
    b = block(n)
    start = b.find('\n{') + 1
    if start <= 0: raise RuntimeError(f'ARB start missing for {n}')
    end = b.find('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', start)
    if end < 0: end = len(b)
    return b[start:end].strip() + '\n'
files = {
 92: 'lib/l10n/app_en.arb',
 93: 'lib/l10n/app_ar.arb',
 94: 'lib/l10n/app_fr.arb',
 95: 'lib/l10n/app_es.arb',
 96: 'lib/l10n/app_de.arb',
 97: 'lib/l10n/app_it.arb',
}
for n, rel in files.items():
    p = root/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(arb(n))
print('L10N FIX #92-#97 applied')
