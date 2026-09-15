from pathlib import Path
root = Path('/home/ubuntu/productchat_studio')
source = Path('/home/ubuntu/upload/24_L10N_COMPLETE_part3.txt').read_text()
pkg = root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'24_L10N_COMPLETE_PART3.txt').write_text(source.rstrip()+'\n')

def block(n):
    start=source.index(f'🔧 FIX #{n}:'); nxt=source.find('🔧 FIX #', start+10)
    return source[start:nxt if nxt >= 0 else len(source)]
def arb(n):
    b=block(n); start=b.find('\n{')+1
    if start <= 0: raise RuntimeError(f'ARB start missing {n}')
    end=b.find('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', start)
    if end < 0: end=len(b)
    return b[start:end].strip().replace('\\$', '$')+'\n'
for n, rel in {101:'lib/l10n/app_zh.arb',102:'lib/l10n/app_ja.arb',103:'lib/l10n/app_ko.arb'}.items():
    p=root/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(arb(n))
print('L10N FIX #101-#103 applied')
