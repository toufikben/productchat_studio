from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PKG = ROOT / 'docs' / 'ai_package'
fixes = (PKG / '01_ALL_FIXES.txt').read_text()
features = (PKG / '02_NEW_FEATURES.txt').read_text()

def write(path, content):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content.rstrip() + '\n')

def extract(text, marker, end_marker):
    start = text.index(marker) + len(marker)
    end = text.index(end_marker, start)
    block = text[start:end]
    block = re.sub(r'^\s*\n', '', block)
    return block.strip()

# FIX 1
write('android/app/src/main/AndroidManifest.xml', '''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <application android:label="ProductChat Studio" android:name="${applicationName}" android:icon="@mipmap/ic_launcher" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:theme="@style/LaunchTheme" android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode" android:hardwareAccelerated="true" android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme" />
            <intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter>
            <intent-filter android:autoVerify="true"><action android:name="android.intent.action.VIEW" /><category android:name="android.intent.category.DEFAULT" /><category android:name="android.intent.category.BROWSABLE" /><data android:scheme="https" android:host="productchat.app" android:pathPrefix="/chat" /><data android:scheme="https" android:host="productchat.app" android:pathPrefix="/recipes" /><data android:scheme="https" android:host="productchat.app" android:pathPrefix="/invite" /><data android:scheme="https" android:host="productchat.app" android:pathPrefix="/paywall" /></intent-filter>
            <intent-filter><action android:name="android.intent.action.VIEW" /><category android:name="android.intent.category.DEFAULT" /><category android:name="android.intent.category.BROWSABLE" /><data android:scheme="productchat" /></intent-filter>
        </activity>
        <provider android:name="androidx.core.content.FileProvider" android:authorities="${applicationId}.fileprovider" android:exported="false" android:grantUriPermissions="true"><meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/file_paths" /></provider>
        <meta-data android:name="flutterEmbedding" android:value="2" />
    </application>
    <queries><intent><action android:name="android.intent.action.PROCESS_TEXT" /><data android:mimeType="text/plain" /></intent></queries>
</manifest>''')
# FIX 2
write('android/app/src/main/res/xml/file_paths.xml', '''<?xml version="1.0" encoding="utf-8"?>
<paths>
    <external-path name="external_files" path="." />
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
</paths>''')
# FIX 3
write('lib/core/feature_flags.dart', '''/// Central feature gates for ProductChat Studio.
class FeatureFlags {
  static const bool backgroundRemoval = true;
  static const bool shadowPresets = true;
  static const bool basicEnhance = true;
  static const bool textEditor = true;
  static const bool layerEditor = true;
  static const bool export = true;
  static const bool history = true;
  static const bool billing = true;
  static const bool modelCenter = true;
  static const bool voiceCommands = true;
  static const bool smartAnalysis = true;
  static const bool floatingNavBar = true;
  static const bool chatStudio = true;
  static const bool miGan = false;
  static const bool realEsrgan = false;
  static const bool relight = false;
  static const bool conversationalEdit = false;
  static const bool recipesAutomation = false;
  static const bool compliance = false;
  static const bool batchProcessing = false;
  static const bool brandIdentity = false;
  static const bool referral = false;
  static const bool useWatermark = true;
  static const bool useQuota = true;
  static const int freeQuota = 3;

  static bool isEnabled(String featureName) {
    const values = <String, bool>{
      'backgroundRemoval': backgroundRemoval, 'shadowPresets': shadowPresets,
      'basicEnhance': basicEnhance, 'textEditor': textEditor, 'layerEditor': layerEditor,
      'export': export, 'history': history, 'billing': billing, 'modelCenter': modelCenter,
      'voiceCommands': voiceCommands, 'smartAnalysis': smartAnalysis,
      'floatingNavBar': floatingNavBar, 'chatStudio': chatStudio, 'miGan': miGan,
      'realEsrgan': realEsrgan, 'relight': relight, 'conversationalEdit': conversationalEdit,
      'recipesAutomation': recipesAutomation, 'compliance': compliance,
      'batchProcessing': batchProcessing, 'brandIdentity': brandIdentity, 'referral': referral,
    };
    return values[featureName] ?? false;
  }
}''')
# FIX 4
constants = (ROOT / 'lib/core/constants.dart').read_text()
constants = constants.replace("static const modelRealEsrganUrl =\n      'https://huggingface.co/Toufikben/productchat-models/resolve/main/RealESRGAN_x4plus.pth';", "static const modelRealEsrganUrl =\n      'https://huggingface.co/Toufikben/productchat-models/resolve/main/real_esrgan_x4.onnx';\n  static const modelRealEsrganSha256 = 'REPLACE_AFTER_UPLOAD';")
write('lib/core/constants.dart', constants)
# FIX 5
manager = (ROOT / 'lib/services/model_manager.dart').read_text()
needle = "  /// Maximum number of times [download]"
insert = "  static const realEsrgan = ModelSpec(\n    id: 'real_esrgan',\n    url: AppConstants.modelRealEsrganUrl,\n    fileName: 'real_esrgan_x4.onnx',\n    sha256: AppConstants.modelRealEsrganSha256,\n  );\n\n"
if 'static const realEsrgan' not in manager:
    manager = manager.replace(needle, insert + needle)
write('lib/services/model_manager.dart', manager)
# FIX 6
seika = (ROOT / 'lib/services/seika_service.dart').read_text()
seika = re.sub(r"  Future<EditResult> upscale\(.*?\n\n  Future<EditResult> addShadow", """  Future<EditResult> upscale(String imagePath, {required int factor}) async {
    final modelPath = await _models.readyPath(ModelManager.realEsrgan);
    if (modelPath == null) {
      return const EditResult.failure('Real-ESRGAN model not downloaded. Go to Settings > Models.');
    }
    return _invoke('upscale', {'imagePath': imagePath, 'factor': factor, 'modelPath': modelPath}, credits: 2);
  }

  Future<EditResult> addShadow""", seika, flags=re.S)
write('lib/services/seika_service.dart', seika)
# FIX 7: provider router, preserving all existing routes and adding new screens.
write('lib/core/router.dart', '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/chat_studio_screen.dart';
import '../features/home/home_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/editor/mask_painter_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/compliance/compliance_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/faq_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/settings/legal_screen.dart';
import '../features/settings/models_screen.dart';
import '../features/settings/brand_screen.dart';
import '../features/billing/paywall_screen.dart';
import '../features/history/history_screen.dart';
import '../features/batch/batch_screen.dart';

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/chat-studio', builder: (_, __) => const ChatStudioScreen()),
    GoRoute(path: '/editor', builder: (_, s) => EditorScreen(imagePath: s.extra as String?)),
    GoRoute(path: '/mask', builder: (_, s) => MaskPainterScreen(imagePath: s.extra as String)),
    GoRoute(path: '/recipes', builder: (_, __) => const RecipesScreen()),
    GoRoute(path: '/compliance', builder: (_, __) => const ComplianceScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/faq', builder: (_, __) => const FAQScreen()),
    GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
    GoRoute(path: '/privacy', builder: (_, __) => const LegalScreen(type: 'privacy')),
    GoRoute(path: '/terms', builder: (_, __) => const LegalScreen(type: 'terms')),
    GoRoute(path: '/models', builder: (_, __) => const ModelsScreen()),
    GoRoute(path: '/brand', builder: (_, __) => const BrandScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
    GoRoute(path: '/batch', builder: (_, __) => const BatchScreen()),
  ],
  errorBuilder: (c, s) => Scaffold(body: Center(child: FilledButton(onPressed: () => c.go('/home'), child: const Text('Go Home')))),
));''')
# FIX 8: preserve non-blocking startup while retaining required service initialization.
write('lib/main.dart', '''import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/platform/locale_service.dart';
import 'services/platform/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));
  runApp(const ProviderScope(child: ProductChatApp()));
  unawaited(_initializeLocalServices());
}

Future<void> _initializeLocalServices() async {
  try {
    await storageService.init();
    await localeController.init();
    await themeModeController.init();
  } catch (error, stackTrace) {
    debugPrint('Optional local service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}''')
# FIX 9 and 10
# light theme already exists; ensure input decoration and TTS dependency.
theme = (ROOT / 'lib/core/theme.dart').read_text()
if 'inputDecorationTheme:' not in theme:
    theme = theme.replace("    appBarTheme: const AppBarTheme(\n      backgroundColor: Colors.transparent,\n      elevation: 0,\n    ),", "    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),\n    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Color(0xFFF0F2F7), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none)),")
write('lib/core/theme.dart', theme)
pub = (ROOT / 'pubspec.yaml').read_text()
if 'flutter_tts:' not in pub:
    pub = pub.replace('  speech_to_text:', '  flutter_tts: ^4.2.0\n  speech_to_text:')
write('pubspec.yaml', pub)

# FEAT 1: new service path required by the package. Keep core service as compatibility API.
voice = extract(features, 'أنشئ الملف بهذا المحتوى:\n\n', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
# first matching block is voice service; extract explicitly from its section
voice_section = features[features.index('🎤 FEAT #1'):]
voice = extract(voice_section, 'أنشئ الملف بهذا المحتوى:\n\n', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
write('lib/services/voice_service.dart', voice)
# FEAT 2, 3, 4, 5, 6
for marker, path in [
    ('🎨 FEAT #2', 'lib/widgets/floating_nav_bar.dart'),
    ('🏠 FEAT #3', 'lib/features/home/home_screen.dart'),
    ('📦 FEAT #4', 'lib/features/settings/models_screen.dart'),
    ('🎭 FEAT #5', 'lib/features/editor/mask_painter_screen.dart'),
    ('💬 FEAT #6', 'lib/features/chat/chat_studio_screen.dart'),
]:
    section = features[features.index(marker):]
    content = extract(section, 'أنشئ الملف بهذا المحتوى:\n\n' if 'استبدل' not in section[:400] else 'استبدل الملف بالكامل بهذا المحتوى:\n\n', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    write(path, content)

# Align the requested feature files with the existing app's shared service path and router provider.
home = (ROOT / 'lib/features/home/home_screen.dart').read_text().replace("import '../chat/chat_screen.dart';", "import '../chat/chat_screen.dart';")
write('lib/features/home/home_screen.dart', home)
app = (ROOT / 'lib/app.dart').read_text().replace('routerConfig: routerProvider,', 'routerConfig: ref.watch(routerProvider),')
write('lib/app.dart', app)
print('AI package applied')
