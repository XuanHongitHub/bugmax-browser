#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${BUGMAX_WORK_DIR:-$PWD/.work/chromium}"
MIN_FREE_GB="${BUGMAX_MIN_FREE_GB:-450}"

echo "uname: $(uname -a)"
if [ "$(uname -s)" != "Darwin" ]; then
  echo "error: runner must be macOS" >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "error: runner must be Apple Silicon arm64" >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found; install Xcode" >&2
  exit 1
fi

xcode_path="$(xcode-select -p)"
echo "xcode-select: ${xcode_path}"
xcodebuild -version

if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  echo "error: Xcode first-launch tasks/license are not complete" >&2
  echo "run: sudo xcodebuild -runFirstLaunch" >&2
  exit 1
fi

mkdir -p "${WORK_DIR}"
free_kb="$(df -Pk "${WORK_DIR}" | awk 'NR==2 {print $4}')"
free_gb="$((free_kb / 1024 / 1024))"
echo "work dir: ${WORK_DIR}"
df -h "${WORK_DIR}"
if [ "${free_gb}" -lt "${MIN_FREE_GB}" ]; then
  echo "error: ${WORK_DIR} has ${free_gb}GB free; need at least ${MIN_FREE_GB}GB" >&2
  exit 1
fi

for tool in git python3 hdiutil codesign xcrun spctl plutil shasum sips; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "error: missing required tool: ${tool}" >&2
    exit 1
  fi
done

echo "preflight ok"
