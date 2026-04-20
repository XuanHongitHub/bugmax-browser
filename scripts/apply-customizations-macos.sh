#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$1"
CHROMIUM_SRC="$2"

PATCH_DIR="${REPO_ROOT}/patches/chromium"
if [ -d "${PATCH_DIR}" ]; then
  shopt -s nullglob
  patches=( "${PATCH_DIR}"/*.patch )
  shopt -u nullglob
  for patch in "${patches[@]}"; do
    echo "Applying patch $(basename "${patch}")"
    git -C "${CHROMIUM_SRC}" apply --3way --whitespace=nowarn "${patch}"
  done
fi

echo "Bugmax customization layer applied (macOS)."
