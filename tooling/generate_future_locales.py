from pathlib import Path
import json

root = Path('lib/l10n')
translations = {
    'es': ('ProductChat Studio', 'Análisis inteligente', 'Sube una imagen de producto para comenzar'),
    'de': ('ProductChat Studio', 'Intelligente Analyse', 'Lade ein Produktbild hoch, um zu beginnen'),
    'it': ('ProductChat Studio', 'Analisi intelligente', 'Carica un’immagine del prodotto per iniziare'),
    'pt': ('ProductChat Studio', 'Análise inteligente', 'Envie uma imagem de produto para começar'),
    'ru': ('ProductChat Studio', 'Умный анализ', 'Загрузите изображение товара, чтобы начать'),
    'tr': ('ProductChat Studio', 'Akıllı Analiz', 'Başlamak için bir ürün görseli yükleyin'),
    'zh': ('ProductChat Studio', '智能分析', '上传产品图片以开始'),
    'ja': ('ProductChat Studio', 'スマート分析', '商品画像をアップロードして開始'),
    'ko': ('ProductChat Studio', '스마트 분석', '시작하려면 제품 이미지를 업로드하세요'),
    'hi': ('ProductChat Studio', 'स्मार्ट विश्लेषण', 'शुरू करने के लिए उत्पाद की फ़ोटो अपलोड करें'),
    'id': ('ProductChat Studio', 'Analisis Cerdas', 'Unggah gambar produk untuk memulai'),
    'fa': ('استودیو محصولات', 'تحلیل هوشمند', 'برای شروع، تصویر محصول را بارگذاری کنید'),
    'ur': ('پروڈکٹ چیٹ اسٹوڈیو', 'اسمارٹ تجزیہ', 'شروع کرنے کے لیے پروڈکٹ کی تصویر اپ لوڈ کریں'),
}

def dart_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)

for locale, (title, analysis, prompt) in translations.items():
    arb = {'@@locale': locale, 'appTitle': title, 'smartAnalysis': analysis, 'uploadPrompt': prompt}
    (root / f'app_{locale}.arb').write_text(json.dumps(arb, ensure_ascii=False) + '\n')
    class_name = 'AppLocalizations' + locale.upper()
    dart = f'''// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for {locale}.
class {class_name} extends AppLocalizations {{
  {class_name}([String locale = '{locale}']) : super(locale);

  @override
  String get appTitle => {dart_string(title)};

  @override
  String get smartAnalysis => {dart_string(analysis)};

  @override
  String get uploadPrompt => {dart_string(prompt)};
}}
'''
    (root / f'app_localizations_{locale}.dart').write_text(dart)

base = root / 'app_localizations.dart'
text = base.read_text()
for locale in translations:
    text = text.replace("import 'app_localizations_fr.dart';", f"import 'app_localizations_fr.dart';\nimport 'app_localizations_{locale}.dart';")
locale_lines = ',\n'.join(f"    Locale('{x}')" for x in ['ar', 'en', 'fr', *translations])
start = text.index('  static const List<Locale> supportedLocales')
end = text.index('\n  ];', start) + len('\n  ];')
text = text[:start] + "  static const List<Locale> supportedLocales = <Locale>[\n" + locale_lines + "\n  ];" + text[end:]
text = text.replace("<String>['ar', 'en', 'fr']", "<String>[" + ', '.join(json.dumps(x) for x in ['ar', 'en', 'fr', *translations]) + "]")
lookup = "    case 'fr':\n      return AppLocalizationsFr();"
for locale in translations:
    lookup += f"\n    case '{locale}':\n      return AppLocalizations{locale.upper()}();"
text = text.replace("    case 'fr':\n      return AppLocalizationsFr();", lookup)
base.write_text(text)
