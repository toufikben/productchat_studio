from pathlib import Path
from PIL import Image

root = Path('store_assets')
icon = Image.open(root / 'app_icon_512.png').convert('RGB').resize((512, 512), Image.Resampling.LANCZOS)
icon.save(root / 'app_icon_512_final.png', format='PNG', optimize=True)
feature = Image.open(root / 'feature_graphic_1024x500.jpg').convert('RGB').resize((1024, 500), Image.Resampling.LANCZOS)
feature.save(root / 'feature_graphic_1024x500_final.jpg', format='JPEG', quality=92, optimize=True, progressive=True)
for path in [root / 'app_icon_512_final.png', root / 'feature_graphic_1024x500_final.jpg']:
    with Image.open(path) as image:
        print(path, image.size, image.mode, path.stat().st_size)
