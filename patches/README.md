# Bugmax patchset

Place Chromium source patches in:

- `patches/chromium/*.patch`

Build scripts will apply patches in lexical order before `gn gen`:

- `scripts/apply-customizations-windows.ps1`
- `scripts/apply-customizations-macos.sh`

Recommended naming:

- `001-branding.patch`
- `010-omnibox-profile-badge.patch`
- `020-search-defaults.patch`
- `030-first-run-profile-defaults.patch`
