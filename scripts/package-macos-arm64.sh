#!/usr/bin/env bash
set -euo pipefail

WORK_DIR="${BUGMAX_WORK_DIR:-$PWD/.work/chromium}"
SRC_DIR="${WORK_DIR}/src"
OUT_DIR="${BUGMAX_OUT_DIR:-out/BugmaxArm64}"
APP_NAME="${BUGMAX_APP_NAME:-Bugmax}"
BUNDLE_ID="${BUGMAX_BUNDLE_ID:-com.buglogin.bugmax}"
SIGN="${BUGMAX_SIGN:-false}"
DIST_DIR="${GITHUB_WORKSPACE:-$PWD}/dist"
APP_DST="${DIST_DIR}/${APP_NAME}.app"
DMG_PATH="${DIST_DIR}/bugmax-macos-arm64.dmg"

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

find_built_app() {
  if [ -d "${SRC_DIR}/${OUT_DIR}/${APP_NAME}.app" ]; then
    echo "${SRC_DIR}/${OUT_DIR}/${APP_NAME}.app"
    return
  fi
  if [ -d "${SRC_DIR}/${OUT_DIR}/Chromium.app" ]; then
    echo "${SRC_DIR}/${OUT_DIR}/Chromium.app"
    return
  fi
  find "${SRC_DIR}/${OUT_DIR}" -maxdepth 1 -name "*.app" -type d | head -n 1
}

APP_SRC="$(find_built_app)"
if [ -z "${APP_SRC}" ] || [ ! -d "${APP_SRC}" ]; then
  echo "error: built app not found under ${SRC_DIR}/${OUT_DIR}" >&2
  exit 1
fi

if [ "${SIGN}" = "true" ]; then
  scripts/sign-notarize-macos.sh "${SRC_DIR}/${OUT_DIR}" "${DIST_DIR}" "${DMG_PATH}"
  if [ -d "${DIST_DIR}/signed/${APP_NAME}.app" ]; then
    APP_DST="${DIST_DIR}/signed/${APP_NAME}.app"
  else
    APP_DST="$(find "${DIST_DIR}/signed" -maxdepth 1 -name "*.app" -type d | head -n 1)"
  fi
else
  cp -R "${APP_SRC}" "${APP_DST}"
  defaults write "${APP_DST}/Contents/Info.plist" CFBundleName "${APP_NAME}"
  defaults write "${APP_DST}/Contents/Info.plist" CFBundleDisplayName "${APP_NAME}"
  defaults write "${APP_DST}/Contents/Info.plist" CFBundleIdentifier "${BUNDLE_ID}"
  plutil -convert xml1 "${APP_DST}/Contents/Info.plist"
fi

actual_name="$(defaults read "${APP_DST}/Contents/Info.plist" CFBundleName)"
actual_bundle="$(defaults read "${APP_DST}/Contents/Info.plist" CFBundleIdentifier)"
if [ "${actual_name}" != "${APP_NAME}" ] || [ "${actual_bundle}" != "${BUNDLE_ID}" ]; then
  echo "error: app branding assertion failed" >&2
  exit 1
fi

if [ "${SIGN}" != "true" ]; then
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
