# Bugmax Browser

Bugmax is the BugLogin-owned Chromium runtime.

Current scope: macOS arm64 build for a self-hosted Apple Silicon runner. The
workflow builds a BugLogin-branded Chromium runtime, packages `Bugmax.app`, and
optionally signs/notarizes the DMG.

The default Chromium ref is pinned to `146.0.7680.82`.
Branding uses the current BugLogin logo at `assets/buglogin-logo.png`; browser
name remains `Bugmax`.

## Workflow

Use `.github/workflows/build-macos-arm64.yml`.

Inputs:

- `chromium_ref`: optional Chromium ref/tag/commit.
- `clean_build`: remove `out/BugmaxArm64` before build.
- `sign`: sign and notarize using configured Apple secrets.

Output:

- `dist/bugmax-macos-arm64.dmg`
- `dist/SHA256SUMS`
- `dist/build-info.json`

See [docs/build-macos-arm64.md](docs/build-macos-arm64.md).

Quick order:

1. Configure the self-hosted Mac mini runner.
2. Run preflight only.
3. Run unsigned vanilla Chromium build.
4. Configure Apple Developer ID secrets.
5. Run signed/notarized build.
6. Extend pinned fingerprint source patches after the first Mac mini build.

Runtime contract: [docs/buglogin-runtime-contract.md](docs/buglogin-runtime-contract.md).
