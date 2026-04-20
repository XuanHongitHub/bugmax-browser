#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$1"
CHROMIUM_SRC="$2"

chmod +x "${REPO_ROOT}/scripts/validate-customization-patchset.sh"
"${REPO_ROOT}/scripts/validate-customization-patchset.sh" "${REPO_ROOT}"

python3 "${REPO_ROOT}/scripts/apply-customizations.py" "${CHROMIUM_SRC}"

echo "Bugmax customization layer applied (macOS)."
