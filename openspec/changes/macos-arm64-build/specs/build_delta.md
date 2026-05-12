# Build Delta

## Added

- Manual `Build macOS arm64` workflow.
- Persistent Chromium work directory via `BUGMAX_WORK_DIR`.
- Disk preflight before Chromium sync.
- Optional Apple Developer ID signing and notarization.

## Removed

- Placeholder source customization scripts.
- GitHub-hosted macOS build target.
- Windows and macOS x64 targets from the first-pass pipeline.
