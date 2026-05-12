# Build macOS arm64

This repository is a build scaffold for a BugLogin Chromium runtime. It does not
carry unverified source patches. Branding, omnibox profile badges, profile icon
behavior, and fingerprint changes must be added as explicit Chromium patches
after a pinned Chromium revision is selected.

## Runner

Use a self-hosted Apple Silicon runner with labels:

```text
self-hosted, macOS, ARM64
```

Recommended disk: 1TB. 500GB can work for one arm64 target if old outputs are
removed.

Bootstrap helper on the Mac mini:

```bash
scripts/bootstrap-macos-runner.sh
```

## Required local tools

- Xcode
- Git
- Python 3
- `hdiutil`, `codesign`, `xcrun`, `spctl`

The workflow downloads `depot_tools` automatically.

## GitHub variables

`BUGMAX_WORK_DIR` controls where Chromium is stored. Use a persistent path on
the Mac mini, for example:

```text
/Users/runner/bugmax-chromium
```

Optional:

- `BUGMAX_MIN_FREE_GB`: defaults to `220`.

## Signing secrets

Only required when workflow input `sign=true`.

- `APPLE_CODESIGN_IDENTITY`: exact Developer ID Application identity.
- `APPLE_NOTARY_PROFILE`: keychain profile name created with `notarytool`.

Example profile setup on the Mac mini:

```bash
xcrun notarytool store-credentials buglogin-notary \
  --apple-id "apple-id@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

Then set `APPLE_NOTARY_PROFILE=buglogin-notary`.

## Manual local run

```bash
export BUGMAX_WORK_DIR=/Users/runner/bugmax-chromium
export BUGMAX_OUT_DIR=out/BugmaxArm64
export BUGMAX_APP_NAME=Bugmax
export BUGMAX_BUNDLE_ID=com.buglogin.bugmax
export BUGMAX_SIGN=false

scripts/preflight-macos-arm64.sh
scripts/prepare-chromium-macos.sh ""
scripts/build-macos-arm64.sh false
scripts/package-macos-arm64.sh
```

## Recommended first run

Run the workflow with:

- `preflight_only=true`
- `sign=false`

CLI:

```bash
scripts/trigger-macos-preflight.sh
```

If that passes, run:

- `preflight_only=false`
- `clean_build=false`
- `sign=false`

CLI:

```bash
scripts/trigger-macos-build.sh XuanHongitHub/bugmax-browser "" false false
```
