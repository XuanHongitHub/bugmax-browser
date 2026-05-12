# Customization Plan

Goal: BugLogin-owned Chromium fork for macOS arm64 first.

## Non-negotiables

- No placeholder Chromium patches.
- No binary reuse from CloakBrowser.
- Every source patch must be tied to a pinned Chromium revision.
- Build must pass on vanilla Chromium before adding fingerprint or UI changes.

## Planned patch groups

1. Branding: app name, bundle id, icon set, About strings. Done.
2. Omnibox profile badge: source-level Views UI patch. Done.
3. Default search engine and first-run preferences. Partial.
4. Profile icon behavior: runtime dock badge first; per-profile app icon only
   after launch model is fixed.
5. Fingerprint layer: deterministic per-profile seed, source-level patches for
   Canvas, WebGL, Audio, Client Hints, WebRTC, locale/timezone, screen metrics.

## Patch policy

Each patch group gets:

- Chromium revision.
- File anchors.
- Build result.
- Runtime smoke result.
- Rollback note.
