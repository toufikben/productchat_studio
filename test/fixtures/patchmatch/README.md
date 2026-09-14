# PatchMatch fixtures

flat_background_product.png: uniform background plus a high-contrast object.
two_tone_background_product.png: connected two-tone background plus a foreground object.
Expected checks: output exists, output is PNG, dimensions are preserved, and Free watermark is visible.
Native alpha-mask quality requires Android instrumentation because PatchMatchRemover is Kotlin code.
