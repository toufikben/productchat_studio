#!/usr/bin/env bash
set +e
cd "$(dirname "$0")"
PASS=0; FAIL=0
check(){ if eval "$2" >/dev/null 2>&1; then echo "✅ $1"; PASS=$((PASS+1)); else echo "❌ $1"; FAIL=$((FAIL+1)); fi; }
for f in pubspec.yaml lib/main.dart lib/app.dart lib/core/theme.dart lib/core/router.dart lib/core/constants.dart lib/services/ai_service.dart lib/services/storage_service.dart lib/services/notification_service.dart lib/services/billing_service.dart lib/services/compliance_service.dart lib/services/marketplace_service.dart lib/widgets/app_widgets.dart l10n.yaml android/app/src/main/AndroidManifest.xml android/app/build.gradle.kts android/app/src/main/res/xml/file_paths.xml ios/Runner/Info.plist ios/Runner/Runner.entitlements ios/Podfile web/index.html web/manifest.json vercel.json lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/services/smart_analysis_service.dart lib/widgets/smart_analysis_panel.dart; do check "$f" "[ -f '$f' ]"; done
for f in app_icons image_preview action_chip credits_pill empty_state gradient_button; do check "widgets/$f.dart" "[ -f lib/widgets/$f.dart ]"; done
for f in faq_screen support_screen legal_screen models_screen brand_screen; do check "settings/$f.dart" "[ -f lib/features/settings/$f.dart ]"; done
for f in MainActivity.kt native/SeikaChannel.kt native/PatchMatchRemover.kt; do check "android/$f" "[ -f android/app/src/main/kotlin/com/productchat/aiphotostudio/$f ]"; done
if command -v flutter >/dev/null; then check 'flutter pub get' 'flutter pub get'; check 'flutter analyze' 'flutter analyze'; check 'flutter test' 'flutter test'; else echo '⚠️ Flutter SDK unavailable; Flutter checks skipped.'; fi
echo "Passed: $PASS | Failed: $FAIL"
[ "$FAIL" -eq 0 ]
