#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${1:-https://github.com/XuanHongitHub/bugmax-browser}"
RUNNER_DIR="${2:-$HOME/actions-runner-bugmax}"
WORK_DIR="${3:-$HOME/bugmax-chromium}"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: run this on macOS" >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "error: Apple Silicon arm64 Mac required" >&2
  exit 1
fi

mkdir -p "${WORK_DIR}" "${RUNNER_DIR}"

echo "Work dir: ${WORK_DIR}"
df -h "${WORK_DIR}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: Xcode is required. Install Xcode, then run:" >&2
  echo "  sudo xcodebuild -runFirstLaunch" >&2
  exit 1
fi

if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  echo "error: Xcode first launch/license not complete. Run:" >&2
  echo "  sudo xcodebuild -runFirstLaunch" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: GitHub CLI is required. Install gh and authenticate first." >&2
  exit 1
fi

echo "Runner setup:"
echo "1. Open GitHub repo runner setup page:"
echo "   ${REPO_URL}/settings/actions/runners/new?arch=arm64&os=macOS"
echo "2. Download/configure runner into:"
echo "   ${RUNNER_DIR}"
echo "3. Use labels:"
echo "   self-hosted,macOS,ARM64"
echo "4. Set repo variable BUGMAX_WORK_DIR to:"
echo "   ${WORK_DIR}"
echo
echo "After runner is online, trigger preflight:"
echo "  gh workflow run build-macos-arm64.yml -R ${REPO_URL#https://github.com/} -f preflight_only=true -f sign=false -f clean_build=false"
