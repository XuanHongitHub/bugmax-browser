#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:?app path required}"
DMG_PATH="${2:?dmg path required}"
APP_NAME="$(basename "${APP_PATH}" .app)"

: "${APPLE_CODESIGN_IDENTITY:?APPLE_CODESIGN_IDENTITY secret is required}"
: "${APPLE_NOTARY_PROFILE:?APPLE_NOTARY_PROFILE secret is required}"

codesign --force --deep --options runtime --timestamp \
  --sign "${APPLE_CODESIGN_IDENTITY}" "${APP_PATH}"
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_PATH}" -ov -format UDZO "${DMG_PATH}"

xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${APPLE_NOTARY_PROFILE}" \
  --wait
xcrun stapler staple "${DMG_PATH}"
spctl --assess --type open --context context:primary-signature --verbose "${DMG_PATH}"
