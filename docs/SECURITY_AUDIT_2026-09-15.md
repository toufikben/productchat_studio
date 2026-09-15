# Security Audit — 2026-09-15

## Scope

The audit covers the repository state after the requested native image channels, local services, test fixtures, and legal review were added. It includes tracked-file secret scanning, repository hygiene checks, dependency and build configuration review, and static inspection of newly added code.

## Results

| Check | Result | Evidence |
|---|---|---|
| Private-key and cloud-key patterns | Passed | No matching credential material found in repository files |
| `.env`, Google service files, and oversized artifacts | Passed | Existing CI hygiene workflow and local file scan |
| Release signing material | Passed | `android/key.properties` and keystore remain untracked/absent |
| Real-ESRGAN fallback removal | Passed | Missing model and inference failure return explicit errors |
| Local data deletion scope | Passed with limitation | Deletion is limited to application-managed paths; model deletion is explicit opt-in |
| Fixture assets | Passed | Six deterministic PNG fixtures, no user data |
| Dependency review | Review required | `device_info_plus` is added; full license resolution requires `flutter pub get` |

## Limitations

Flutter and the Android SDK toolchain are not installed in this sandbox, so `flutter analyze`, dependency resolution, and APK compilation cannot be executed locally. These checks must run in GitHub Actions. A real Android device is also required to validate ONNX operators, model checksums, memory use, and latency.

This document is not a legal opinion or a guarantee of vulnerability-free software. The legal review remains subject to maintainer and counsel approval before commercial publication.
