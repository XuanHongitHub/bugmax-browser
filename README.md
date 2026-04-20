# Bugmax Browser

Bugmax is a custom Chromium runtime for BugLogin.

## Goals

- Build from `chromium/src`
- Keep BugLogin integration adapter-only
- Runtime-only packaging (no heavy intermediate artifacts)
- Support Windows and macOS builds via GitHub Actions

## CI

Use workflow: `.github/workflows/build-bugmax.yml`

Manual trigger inputs:
- `build_profile`: `full` or `smoke`
- `chromium_ref`: git ref/tag (optional)

## Output Artifacts

- `bugmax-windows-x64-runtime`
- `bugmax-macos-arm64-runtime`
- `bugmax-macos-x64-runtime`
