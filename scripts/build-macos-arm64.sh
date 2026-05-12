#!/usr/bin/env bash
set -euo pipefail

CLEAN_BUILD="${1:-false}"
WORK_DIR="${BUGMAX_WORK_DIR:-$PWD/.work/chromium}"
SRC_DIR="${WORK_DIR}/src"
OUT_DIR="${BUGMAX_OUT_DIR:-out/BugmaxArm64}"
DEPOT_TOOLS_DIR="${WORK_DIR}/depot_tools"
APPLY_CUSTOMIZATIONS="${BUGMAX_APPLY_CUSTOMIZATIONS:-true}"

if [ ! -d "${SRC_DIR}/.git" ]; then
  echo "error: Chromium source not found at ${SRC_DIR}; run prepare first" >&2
  exit 1
fi

export PATH="${DEPOT_TOOLS_DIR}:$PATH"
cd "${SRC_DIR}"

if [ "${CLEAN_BUILD}" = "true" ]; then
  rm -rf "${OUT_DIR}"
fi

if [ "${APPLY_CUSTOMIZATIONS}" = "true" ]; then
  python3 "${GITHUB_WORKSPACE:-$PWD}/scripts/apply-buglogin-customizations.py" "${SRC_DIR}"
fi

mkdir -p "${OUT_DIR}"
cat > "${OUT_DIR}/args.gn" <<'EOF'
is_debug = false
is_component_build = false
symbol_level = 0
blink_symbol_level = 0
target_os = "mac"
target_cpu = "arm64"
enable_nacl = false
EOF

gn gen "${OUT_DIR}"
autoninja -C "${OUT_DIR}" chrome
