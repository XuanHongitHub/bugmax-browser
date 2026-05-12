#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:?chromium out dir required}"
DIST_DIR="${2:?dist dir required}"
DMG_PATH="${3:?dmg path required}"
APP_NAME="${BUGMAX_APP_NAME:-Bugmax}"

: "${APPLE_CODESIGN_IDENTITY:?APPLE_CODESIGN_IDENTITY secret is required}"
: "${APPLE_NOTARY_PROFILE:?APPLE_NOTARY_PROFILE secret is required}"

SIGN_CHROME="$(find "${OUT_DIR}" -path "* Packaging/sign_chrome.py" -type f | head -n 1)"
if [ -z "${SIGN_CHROME}" ]; then
  echo "error: Chromium signing tool not found; build target chrome/installer/mac first" >&2
  exit 1
fi

SIGNED_DIR="${DIST_DIR}/signed"
rm -rf "${SIGNED_DIR}"

python3 "${SIGN_CHROME}" \
  --input "${OUT_DIR}" \
  --output "${SIGNED_DIR}" \
  --identity "${APPLE_CODESIGN_IDENTITY}" \
  --disable-packaging

SIGNED_APP="${SIGNED_DIR}/${APP_NAME}.app"
if [ ! -d "${SIGNED_APP}" ]; then
  SIGNED_APP="$(find "${SIGNED_DIR}" -maxdepth 1 -name "*.app" -type d | head -n 1)"
fi
if [ -z "${SIGNED_APP}" ] || [ ! -d "${SIGNED_APP}" ]; then
  echo "error: signed app not found under ${SIGNED_DIR}" >&2
  exit 1
fi

codesign --verify --deep --strict --verbose=2 "${SIGNED_APP}"

hdiutil create -volname "${APP_NAME}" -srcfolder "${SIGNED_APP}" -ov -format UDZO "${DMG_PATH}"

xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${APPLE_NOTARY_PROFILE}" \
  --wait
xcrun stapler staple "${DMG_PATH}"
spctl --assess --type open --context context:primary-signature --verbose "${DMG_PATH}"
