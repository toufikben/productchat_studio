#!/usr/bin/env bash
set +e
cd "$(dirname "$0")"
pass=0; fail=0
check(){ if eval "$2" >/dev/null 2>&1; then printf '✅ %s\n' "$1"; pass=$((pass+1)); else printf '❌ %s\n' "$1"; fail=$((fail+1)); fi; }
check 'pubspec.yaml' '[ -f pubspec.yaml ]'; check 'lib/main.dart' '[ -f lib/main.dart ]'; check 'smart analysis service' '[ -f lib/services/smart_analysis_service.dart ]'; check 'smart analysis panel' '[ -f lib/widgets/smart_analysis_panel.dart ]'; check 'test suite' '[ -f test/smart_analysis_service_test.dart ]'; check 'FIX_PACKAGE.sh' '[ -x FIX_PACKAGE.sh ]'
if command -v flutter >/dev/null 2>&1; then check 'flutter pub get' 'flutter pub get'; check 'flutter analyze' 'flutter analyze'; else printf '⚠️ Flutter SDK unavailable; Flutter checks skipped.\n'; fi
printf '\nPassed: %s | Failed: %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
