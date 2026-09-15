#!/usr/bin/env bash
# Verify public model availability and the checksums pinned by the Flutter app.
set -euo pipefail

BASE_URL="https://huggingface.co/Toufikben/productchat-models/resolve/main"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

verify_model() {
  local filename="$1"
  local expected_sha256="$2"
  local destination="$WORK_DIR/$filename"

  curl --fail --silent --show-error --location --retry 2 \
    --connect-timeout 15 --max-time 180 \
    "$BASE_URL/$filename" --output "$destination"

  local actual_sha256
  actual_sha256="$(sha256sum "$destination" | awk '{print $1}')"
  if [[ "$actual_sha256" != "$expected_sha256" ]]; then
    printf 'SHA-256 mismatch for %s: expected %s, got %s\n' \
      "$filename" "$expected_sha256" "$actual_sha256" >&2
    return 1
  fi

  printf '%s\t%s bytes\tSHA-256 OK\n' \
    "$filename" "$(stat --format='%s' "$destination")"
}

verify_model \
  "migan.onnx" \
  "593eba0b7e04730f1b61c0a3cbca68d97d8d6a7ff5c6a44a7b9d7fcd880fc5ae"
verify_model \
  "lama_fp16.onnx" \
  "37f2e4888eb27aa08841786b506fa094156c497de3d954ebf7a297c61a7fb4ea"
verify_model \
  "real_esrgan_x4.onnx" \
  "5c586662929cbc686c1a5c38d9c060dbdb4ea5863a1f7672b8c0761e6b89c033"
