#!/usr/bin/env bash
set -euo pipefail

TARGET="$1"      # macos-arm64 | macos-x64
PROFILE="$2"     # full | smoke
CHROMIUM_REF="${3:-}"
APPLY_CUSTOMIZATIONS="${4:-true}"

WORK_DIR="${GITHUB_WORKSPACE}/work"
DEPOT_DIR="${GITHUB_WORKSPACE}/depot_tools"
SRC_DIR="${WORK_DIR}/src"
OUT_DIR="${SRC_DIR}/out/Release"
DIST_DIR="${GITHUB_WORKSPACE}/dist/${TARGET}"
REPO_ROOT="${GITHUB_WORKSPACE}"

mkdir -p "${WORK_DIR}" "${DIST_DIR}"

if [ ! -d "${DEPOT_DIR}" ]; then
  git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_DIR}"
fi
export PATH="${DEPOT_DIR}:$PATH"

cd "${WORK_DIR}"
if [ ! -d "${SRC_DIR}" ]; then
  fetch --nohooks --no-history chromium
fi

cd "${SRC_DIR}"
if [ -n "${CHROMIUM_REF}" ]; then
  git fetch --tags --depth 1 origin "${CHROMIUM_REF}"
  git checkout "${CHROMIUM_REF}"
fi

gclient sync -D --force --with_branch_heads --with_tags --no-history

gclient runhooks

if [ "${APPLY_CUSTOMIZATIONS}" = "true" ]; then
  chmod +x "${REPO_ROOT}/scripts/apply-customizations-macos.sh"
  "${REPO_ROOT}/scripts/apply-customizations-macos.sh" "${REPO_ROOT}" "${SRC_DIR}"
fi

cat > "${SRC_DIR}/out/Release/args.gn" <<EOF
is_debug=false
is_component_build=false
symbol_level=0
blink_symbol_level=0
enable_nacl=false
target_cpu="$( [ "${TARGET}" = "macos-arm64" ] && echo arm64 || echo x64 )"
EOF

gn gen out/Release

if [ "${PROFILE}" = "smoke" ]; then
  autoninja -C out/Release chrome/test:unit_tests
else
  autoninja -C out/Release chrome
fi

# Runtime-only packaging
if [ -d "${OUT_DIR}/Chromium.app" ]; then
  cp -R "${OUT_DIR}/Chromium.app" "${DIST_DIR}/Bugmax.app"
fi
if [ -f "${REPO_ROOT}/config/initial_preferences.json" ]; then
  cp "${REPO_ROOT}/config/initial_preferences.json" "${DIST_DIR}/initial_preferences"
fi
if [ -f "${OUT_DIR}/icudtl.dat" ]; then cp "${OUT_DIR}/icudtl.dat" "${DIST_DIR}/"; fi
if [ -f "${OUT_DIR}/v8_context_snapshot.bin" ]; then cp "${OUT_DIR}/v8_context_snapshot.bin" "${DIST_DIR}/"; fi
if [ -f "${OUT_DIR}/snapshot_blob.bin" ]; then cp "${OUT_DIR}/snapshot_blob.bin" "${DIST_DIR}/"; fi

cd "${DIST_DIR}"
tar -czf "${GITHUB_WORKSPACE}/bugmax-${TARGET}.tar.gz" .
