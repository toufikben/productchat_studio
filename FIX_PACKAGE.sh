#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p lib/{core,models,services,features/{splash,onboarding,chat,editor,recipes,compliance,settings,billing,history,batch},widgets,l10n/generated} android/app/src/main/kotlin/com/productchat/aiphotostudio/native android/app/src/main/res/xml ios/Runner/Channels web .github/workflows
printf 'ProductChat Studio fix package: directory and bridge layout prepared.\n'
