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
- `macos_targets`: `arm64-only` (default) or `arm64-and-x64`
- `chromium_ref`: git ref/tag (optional)

## Output Artifacts

- `bugmax-windows-x64-runtime`
- `bugmax-macos-arm64-runtime`
- `bugmax-macos-x64-runtime`

## Release Process

- One-shot release checklist: `docs/release-one-shot-checklist.md`
- One-shot build workflow is manual-only to avoid accidental long rebuilds on every push.
- Release build always applies required Bugmax customization patchset before compile.
