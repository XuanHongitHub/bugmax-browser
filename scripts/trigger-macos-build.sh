#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-XuanHongitHub/bugmax-browser}"
CHROMIUM_REF="${2:-}"
CLEAN_BUILD="${3:-false}"
SIGN="${4:-false}"

gh workflow run build-macos-arm64.yml \
  -R "${REPO}" \
  -f preflight_only=false \
  -f sign="${SIGN}" \
  -f clean_build="${CLEAN_BUILD}" \
  -f chromium_ref="${CHROMIUM_REF}"

echo "Build queued. Watch:"
echo "  gh run list -R ${REPO} --workflow build-macos-arm64.yml --limit 1"
