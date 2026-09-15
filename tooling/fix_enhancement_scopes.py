from pathlib import Path
p=Path('/home/ubuntu/productchat_studio/lib/services/enhancement_presets_service.dart')
s=p.read_text()
repls={
'EnhancePreset.auto':'auto', 'EnhancePreset.productStudio':'studio', 'EnhancePreset.marketplaceHero':'marketplace',
'EnhancePreset.instagramReady':'instagram', 'EnhancePreset.softProduct':'soft', 'EnhancePreset.highContrast':'contrast',
'EnhancePreset.warmCommerce':'warm', 'EnhancePreset.cleanWhite':'white',
}
for case, name in repls.items():
    start=s.index(f'case {case}:')
    end=s.find('\n        case ', start+8)
    if end<0: end=s.index('\n      }', start)
    chunk=s[start:end]
    chunk=chunk.replace('final r2 =', f'final r2_{name} =').replace('if (r2.ok)', f'if (r2_{name}.ok)').replace('r2.outputPath!', f'r2_{name}.outputPath!')
    chunk=chunk.replace('final r =', f'final r_{name} =').replace('if (r.ok)', f'if (r_{name}.ok)').replace('r.outputPath!', f'r_{name}.outputPath!')
    s=s[:start]+chunk+s[end:]
p.write_text(s)
