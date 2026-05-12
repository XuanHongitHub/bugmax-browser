#!/usr/bin/env bash
set -euo pipefail

CHROMIUM_REF="${1:-146.0.7680.82}"
WORK_DIR="${BUGMAX_WORK_DIR:-$PWD/.work/chromium}"
DEPOT_TOOLS_DIR="${WORK_DIR}/depot_tools"
SRC_DIR="${WORK_DIR}/src"

min_free_gb="${BUGMAX_MIN_FREE_GB:-450}"
mkdir -p "${WORK_DIR}"
free_kb="$(df -Pk "${WORK_DIR}" | awk 'NR==2 {print $4}')"
free_gb="$((free_kb / 1024 / 1024))"
if [ "${free_gb}" -lt "${min_free_gb}" ]; then
  echo "error: ${WORK_DIR} has ${free_gb}GB free; need at least ${min_free_gb}GB before sync" >&2
  df -h "${WORK_DIR}" >&2
  exit 1
fi

if [ ! -d "${DEPOT_TOOLS_DIR}/.git" ]; then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
else
  git -C "${DEPOT_TOOLS_DIR}" pull --ff-only
fi

export PATH="${DEPOT_TOOLS_DIR}:$PATH"

cd "${WORK_DIR}"
if [ ! -d "${SRC_DIR}/.git" ]; then
  fetch --no-history --nohooks chromium
fi

cd "${SRC_DIR}"
git fetch --tags origin "${CHROMIUM_REF}"
git checkout --detach FETCH_HEAD

gclient sync --no-history --nohooks --delete_unversioned_trees
gclient runhooks

git rev-parse HEAD > "${WORK_DIR}/chromium_revision.txt"
