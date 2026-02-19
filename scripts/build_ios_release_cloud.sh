#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_API_BASE_URL="http://47.100.221.135:8080"
API_BASE_URL="${1:-${EVENT_API_BASE_URL:-${DEFAULT_API_BASE_URL}}}"
NORMALIZED_BASE_URL="${API_BASE_URL%/}"

if [[ "${NORMALIZED_BASE_URL}" != http://* && "${NORMALIZED_BASE_URL}" != https://* ]]; then
  echo "EVENT_API_BASE_URL must start with http:// or https://"
  exit 1
fi

cd "${PROJECT_ROOT}"

flutter build ios --release --dart-define=EVENT_API_BASE_URL="${NORMALIZED_BASE_URL}"

echo
echo "Build complete:"
echo "  - App bundle: ${PROJECT_ROOT}/build/ios/iphoneos/Runner.app"
echo "  - API base:   ${NORMALIZED_BASE_URL}"
