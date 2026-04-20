# Bugmax One-Shot Custom Design (2026-04-20)

## Scope

Build only after all required Bugmax customizations are implemented and reviewed once.

## Required customizations before release build

1. Branding layer
- Product naming and visible branding strings.
- App metadata consistency across Windows/macOS packaging.

2. Omnibox custom layer
- Profile badge shown before URL text.
- Fallback behavior when profile context is missing.

3. Search/omnibox behavior
- Default search provider behavior aligned with normal Google query handling.
- Guard against malformed URL coercion for plain query strings.

4. First-run/profile defaults
- Initial preferences file included in runtime artifact.
- No dependency on old BugLogin runtime hacks for baseline behavior.

## Build gate policy

- Workflow must be manual-only.
- Release build must fail fast if required Chromium patch files are missing.
- Required patch set:
  - `001-branding.patch`
  - `010-omnibox-profile-badge.patch`
  - `020-search-defaults.patch`
  - `030-first-run-defaults.patch`

## Out of scope for this batch

- Fingerprint parity claims with commercial anti-detect browsers.
- Code signing/notarization automation.
