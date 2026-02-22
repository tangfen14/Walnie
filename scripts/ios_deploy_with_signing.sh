#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_API_BASE_URL="http://47.100.221.135:8080"
DEFAULT_CC_DEVICE_ID="00008130-001C48960E93803A"
DEFAULT_WANG_DEVICE_ID="00008130-000814380192001C"

ACCOUNT=""
TEAM_ID=""
BUNDLE_ID=""
DEVICE_ID=""
API_BASE_URL="${EVENT_API_BASE_URL:-${DEFAULT_API_BASE_URL}}"
SKIP_CLEAN=0
SKIP_HEALTH=0
PREPARE_ONLY=0

usage() {
  cat <<'EOF'
Usage:
  ./scripts/ios_deploy_with_signing.sh --account <cc|wang> [options]
  ./scripts/ios_deploy_with_signing.sh --team <TEAM_ID> --bundle <BUNDLE_ID> [options]

Options:
  --account <cc|wang>   Use preset signing profile.
  --team <TEAM_ID>      Apple Development Team ID (for custom profile).
  --bundle <BUNDLE_ID>  Main app bundle id, must end with .walnie (e.g. com.cc.walnie).
  --device <DEVICE_ID>  Target device id from `flutter devices` (cc/wang presets have defaults).
  --api <URL>           EVENT_API_BASE_URL (default: http://47.100.221.135:8080).
  --skip-clean          Skip `flutter clean`.
  --skip-health-check   Skip backend /health check.
  --prepare-only        Only switch signing/app group files, do not run install.
  -h, --help            Show this help.

Examples:
  ./scripts/ios_deploy_with_signing.sh --account cc
  ./scripts/ios_deploy_with_signing.sh --account wang
  ./scripts/ios_deploy_with_signing.sh --team HBZ55TLU3M --bundle com.wang.walnie --api http://47.100.221.135:8080
EOF
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

require_file() {
  local file="$1"
  [[ -f "${file}" ]] || fail "Required file not found: ${file}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --account)
      [[ $# -ge 2 ]] || fail "--account requires a value"
      ACCOUNT="$2"
      shift 2
      ;;
    --team)
      [[ $# -ge 2 ]] || fail "--team requires a value"
      TEAM_ID="$2"
      shift 2
      ;;
    --bundle)
      [[ $# -ge 2 ]] || fail "--bundle requires a value"
      BUNDLE_ID="$2"
      shift 2
      ;;
    --device)
      [[ $# -ge 2 ]] || fail "--device requires a value"
      DEVICE_ID="$2"
      shift 2
      ;;
    --api)
      [[ $# -ge 2 ]] || fail "--api requires a value"
      API_BASE_URL="$2"
      shift 2
      ;;
    --skip-clean)
      SKIP_CLEAN=1
      shift
      ;;
    --skip-health-check)
      SKIP_HEALTH=1
      shift
      ;;
    --prepare-only)
      PREPARE_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

if [[ -n "${ACCOUNT}" ]]; then
  case "${ACCOUNT}" in
    cc)
      TEAM_ID="992657Q3VP"
      BUNDLE_ID="com.cc.walnie"
      if [[ -z "${DEVICE_ID}" ]]; then
        DEVICE_ID="${DEFAULT_CC_DEVICE_ID}"
      fi
      ;;
    wang)
      TEAM_ID="HBZ55TLU3M"
      BUNDLE_ID="com.wang.walnie"
      if [[ -z "${DEVICE_ID}" ]]; then
        DEVICE_ID="${DEFAULT_WANG_DEVICE_ID}"
      fi
      ;;
    *)
      fail "Unsupported --account: ${ACCOUNT}. Use cc or wang."
      ;;
  esac
fi

[[ -n "${TEAM_ID}" ]] || fail "Team ID is required. Use --account or --team."
[[ -n "${BUNDLE_ID}" ]] || fail "Bundle ID is required. Use --account or --bundle."

if [[ "${BUNDLE_ID}" != com.*.walnie ]]; then
  fail "Bundle ID must look like com.<name>.walnie, got: ${BUNDLE_ID}"
fi

NORMALIZED_BASE_URL="${API_BASE_URL%/}"
if [[ "${NORMALIZED_BASE_URL}" != http://* && "${NORMALIZED_BASE_URL}" != https://* ]]; then
  fail "API base URL must start with http:// or https://"
fi

EXT_BUNDLE_ID="${BUNDLE_ID}.liveactivity"
APP_GROUP_ID="group.${BUNDLE_ID}.shared"

PBXPROJ="${PROJECT_ROOT}/ios/Runner.xcodeproj/project.pbxproj"
RUNNER_ENTITLEMENTS="${PROJECT_ROOT}/ios/Runner/Runner.entitlements"
EXT_ENTITLEMENTS="${PROJECT_ROOT}/ios/WalnieLiveActivityExtension/WalnieLiveActivityExtension.entitlements"
EXT_SWIFT="${PROJECT_ROOT}/ios/WalnieLiveActivityExtension/WalnieLiveActivityExtension.swift"
MAIN_DART="${PROJECT_ROOT}/lib/main.dart"
PROVIDERS_DART="${PROJECT_ROOT}/lib/app/providers.dart"

require_file "${PBXPROJ}"
require_file "${RUNNER_ENTITLEMENTS}"
require_file "${EXT_ENTITLEMENTS}"
require_file "${EXT_SWIFT}"
require_file "${MAIN_DART}"
require_file "${PROVIDERS_DART}"

echo "=== Walnie iOS deploy ==="
echo "Team ID:         ${TEAM_ID}"
echo "App Bundle ID:   ${BUNDLE_ID}"
echo "Ext Bundle ID:   ${EXT_BUNDLE_ID}"
echo "App Group ID:    ${APP_GROUP_ID}"
echo "API Base URL:    ${NORMALIZED_BASE_URL}"
if [[ -n "${DEVICE_ID}" ]]; then
  echo "Device ID:       ${DEVICE_ID}"
else
  echo "Device ID:       (interactive select)"
fi
echo

# Keep Runner target and LiveActivity extension target in the same signing identity and namespace.
perl -0777 -i -pe "s|DEVELOPMENT_TEAM = [A-Z0-9]+;|DEVELOPMENT_TEAM = ${TEAM_ID};|g; s|PRODUCT_BUNDLE_IDENTIFIER = com\\.[^;]*\\.walnie\\.liveactivity;|PRODUCT_BUNDLE_IDENTIFIER = ${EXT_BUNDLE_ID};|g; s|PRODUCT_BUNDLE_IDENTIFIER = com\\.[^;]*\\.walnie;|PRODUCT_BUNDLE_IDENTIFIER = ${BUNDLE_ID};|g" "${PBXPROJ}"

# Keep app group id consistent across iOS entitlements, Swift extension, and Dart bridge setup.
for file in "${RUNNER_ENTITLEMENTS}" "${EXT_ENTITLEMENTS}" "${EXT_SWIFT}" "${MAIN_DART}" "${PROVIDERS_DART}"; do
  perl -0777 -i -pe "s|group\\.com\\.[A-Za-z0-9_.-]+\\.walnie\\.shared|${APP_GROUP_ID}|g" "${file}"
done

echo "Signing + app group switched."
echo

cd "${PROJECT_ROOT}"

if [[ "${SKIP_HEALTH}" -eq 0 ]]; then
  ./scripts/check_backend_health.sh "${NORMALIZED_BASE_URL}"
  echo
fi

if [[ "${SKIP_CLEAN}" -eq 0 ]]; then
  flutter clean
fi
flutter pub get

if [[ "${PREPARE_ONLY}" -eq 1 ]]; then
  echo
  echo "Prepare-only complete. You can now run:"
  echo "  flutter run --release --dart-define=EVENT_API_BASE_URL=${NORMALIZED_BASE_URL}"
  exit 0
fi

RUN_CMD=(flutter run --release "--dart-define=EVENT_API_BASE_URL=${NORMALIZED_BASE_URL}")
if [[ -n "${DEVICE_ID}" ]]; then
  RUN_CMD+=(-d "${DEVICE_ID}")
fi

echo
echo "Executing: ${RUN_CMD[*]}"
"${RUN_CMD[@]}"
