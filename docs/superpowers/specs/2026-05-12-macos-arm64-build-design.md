# macOS arm64 Build Design

## Scope

Build and package a macOS arm64 Chromium runtime on a self-hosted Apple Silicon
runner.

## Constraints

- Do not use GitHub-hosted macOS runners.
- Do not apply unverified Chromium patches.
- Do not reuse CloakBrowser binaries.
- Keep signing optional until Apple Developer ID credentials are configured.

## Output

- `bugmax-macos-arm64.dmg`
- `SHA256SUMS`
- `build-info.json`

## Follow-up

After a vanilla build passes, add pinned Chromium patches for branding, omnibox
profile badge, search defaults, and fingerprint behavior.
