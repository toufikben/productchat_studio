#!/usr/bin/env bash
set -euo pipefail
command -v flutter >/dev/null || { echo 'Flutter SDK required'; exit 2; }
flutter build apk --profile
cat <<'TABLE'
Target metrics: startup <2s; background removal <200ms; shadow <300ms; export <500ms; MI-GAN <1s; LaMa <2.5s; DreamLite <4s; memory <400MB; APK without models <50MB.
TABLE
