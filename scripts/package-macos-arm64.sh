#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${BUGMAX_WORK_DIR:-$PWD/.work/chromium}"
SRC_DIR="${WORK_DIR}/src"
OUT_DIR="${BUGMAX_OUT_DIR:-out/BugmaxArm64}"
APP_NAME="${BUGMAX_APP_NAME:-Bugmax}"
BUNDLE_ID="${BUGMAX_BUNDLE_ID:-com.buglogin.bugmax}"
SIGN="${BUGMAX_SIGN:-false}"
DIST_DIR="${GITHUB_WORKSPACE:-$PWD}/dist"
APP_SRC="${SRC_DIR}/${OUT_DIR}/Chromium.app"
APP_DST="${DIST_DIR}/${APP_NAME}.app"
DMG_PATH="${DIST_DIR}/bugmax-macos-arm64.dmg"

if [ ! -d "${APP_SRC}" ]; then
  echo "error: built app not found: ${APP_SRC}" >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"
cp -R "${APP_SRC}" "${APP_DST}"

defaults write "${APP_DST}/Contents/Info.plist" CFBundleName "${APP_NAME}"
defaults write "${APP_DST}/Contents/Info.plist" CFBundleDisplayName "${APP_NAME}"
defaults write "${APP_DST}/Contents/Info.plist" CFBundleIdentifier "${BUNDLE_ID}"
plutil -convert xml1 "${APP_DST}/Contents/Info.plist"

if [ "${SIGN}" = "true" ]; then
  scripts/sign-notarize-macos.sh "${APP_DST}" "${DMG_PATH}"
else
  hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_DST}" -ov -format UDZO "${DMG_PATH}"
fi

(
  cd "${DIST_DIR}"
  shasum -a 256 "$(basename "${DMG_PATH}")" > SHA256SUMS
)

cat > "${DIST_DIR}/build-info.json" <<EOF
{
  "app": "${APP_NAME}",
  "bundle_id": "${BUNDLE_ID}",
  "platform": "macos-arm64",
  "chromium_revision": "$(cat "${WORK_DIR}/chromium_revision.txt" 2>/dev/null || true)",
  "signed": ${SIGN}
}
EOF
