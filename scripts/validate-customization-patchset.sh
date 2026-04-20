#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$1"
PATCH_ROOT="${REPO_ROOT}/patches/chromium"

required=(
  "001-branding.patch"
  "010-omnibox-profile-badge.patch"
  "020-search-defaults.patch"
  "030-first-run-defaults.patch"
)

if [ ! -d "${PATCH_ROOT}" ]; then
  echo "Missing patch directory: ${PATCH_ROOT}" >&2
  exit 1
fi

missing=0
for name in "${required[@]}"; do
  path="${PATCH_ROOT}/${name}"
  if [ ! -f "${path}" ]; then
    echo "Missing: ${name}" >&2
    missing=1
    continue
  fi
  if [ ! -s "${path}" ]; then
    echo "Empty: ${name}" >&2
    missing=1
  fi
done

if [ "${missing}" -ne 0 ]; then
  echo "Stop build until one-shot custom patchset is complete." >&2
  exit 1
fi

echo "Required Bugmax patchset present."
