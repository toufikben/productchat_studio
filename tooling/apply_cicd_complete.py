from pathlib import Path
root=Path('/home/ubuntu/productchat_studio')
source=Path('/home/ubuntu/upload/CICD_COMPLETE.txt').read_text()
pkg=root/'docs'/'ai_package'; pkg.mkdir(parents=True, exist_ok=True); (pkg/'25_CICD_COMPLETE.txt').write_text(source.rstrip()+'\n')
def block(n):
    start=source.index(f'🔧 FIX #{n}:'); nxt=source.find('🔧 FIX #', start+10)
    return source[start:nxt if nxt >= 0 else len(source)]
def content(n, marker):
    b=block(n); start=b.find(marker)
    if start < 0: raise RuntimeError(f'marker missing {n}')
    out=b[start:]
    end=out.find('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    if end >= 0: out=out[:end]
    return out.strip()+'\n'
files={
 109:('.github/workflows/analysis.yml','name: Analyze & Test'),
 110:('.github/workflows/build-release-aab.yml','name: Build Release AAB'),
 111:('.github/workflows/secrets-check.yml','name: Secrets & Hygiene'),
 112:('.github/workflows/deploy-web.yml','name: Deploy Web to Vercel'),
 113:('.github/workflows/release-ios.yml','name: Build iOS'),
 114:('.github/workflows/quality.yml','name: Quality Check'),
 115:('.github/dependabot.yml','version: 2'),
 116:('.github/PULL_REQUEST_TEMPLATE.md','## 📝 Description'),
}
for n,(rel,marker) in files.items():
    p=root/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(content(n,marker))
print('CI/CD FIX #109-#116 applied')
