#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-XuanHongitHub/bugmax-browser}"

gh workflow run build-macos-arm64.yml \
  -R "${REPO}" \
  -f preflight_only=true \
  -f sign=false \
  -f clean_build=false \
  -f chromium_ref=""

echo "Preflight queued. Watch:"
echo "  gh run list -R ${REPO} --workflow build-macos-arm64.yml --limit 1"
