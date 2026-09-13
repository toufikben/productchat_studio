#!/usr/bin/env bash
set -euo pipefail
command -v flutter >/dev/null || { echo 'Flutter SDK is required for device testing.'; exit 2; }
flutter devices
flutter build apk --debug
printf 'Install with: adb install -r build/app/outputs/flutter-apk/app-debug.apk\n'
