#!/usr/bin/env bash

set -euo pipefail

DEFAULT_API_BASE_URL="http://47.100.221.135:8080"
API_BASE_URL="${1:-${EVENT_API_BASE_URL:-${DEFAULT_API_BASE_URL}}}"
NORMALIZED_BASE_URL="${API_BASE_URL%/}"
HEALTH_URL="${NORMALIZED_BASE_URL}/health"

echo "Checking backend health: ${HEALTH_URL}"
curl --fail --silent --show-error --max-time 10 "${HEALTH_URL}"
echo
echo "Backend is healthy."
