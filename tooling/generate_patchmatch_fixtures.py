from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1] / "test" / "fixtures" / "patchmatch"
root.mkdir(parents=True, exist_ok=True)

flat = Image.new("RGBA", (320, 240), (34, 120, 190, 255))
draw = ImageDraw.Draw(flat)
draw.rounded_rectangle((95, 50, 225, 205), radius=18, fill=(238, 180, 62, 255), outline=(255, 255, 255, 255), width=4)
draw.ellipse((132, 72, 188, 128), fill=(210, 70, 65, 255))
flat.save(root / "flat_background_product.png")

two_tone = Image.new("RGBA", (320, 240), (220, 220, 220, 255))
draw = ImageDraw.Draw(two_tone)
draw.rectangle((0, 120, 320, 240), fill=(205, 205, 205, 255))
draw.rectangle((110, 65, 210, 195), fill=(35, 160, 105, 255))
draw.rectangle((135, 35, 185, 70), fill=(35, 160, 105, 255))
two_tone.save(root / "two_tone_background_product.png")

(root / "README.md").write_text(
    "# PatchMatch fixtures\n\n"
    "flat_background_product.png: uniform background plus a high-contrast object.\n"
    "two_tone_background_product.png: connected two-tone background plus a foreground object.\n"
    "Expected checks: output exists, output is PNG, dimensions are preserved, and Free watermark is visible.\n"
    "Native alpha-mask quality requires Android instrumentation because PatchMatchRemover is Kotlin code.\n",
    encoding="utf-8",
)
