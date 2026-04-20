# Bugmax One-Shot Release Checklist

Use this checklist to minimize rebuild loops and ship with a single release build.

## 1) Scope Freeze

- [ ] Final browser name and product branding are frozen.
- [ ] Final bundle identifiers / app IDs are frozen for macOS and Windows.
- [ ] Final icon set is frozen (`.icns`, `.ico`, and all required source assets).
- [ ] Omnibox profile badge behavior is frozen (position, format, fallback rules).
- [ ] Search behavior is frozen (Google-like query flow, no unwanted `http://` coercion).

## 2) Chromium Base Freeze

- [ ] Exact Chromium ref/tag is chosen and documented.
- [ ] Build profile/flags are frozen for release.
- [ ] Patch apply target is verified against the exact ref (no moving branch target).

## 3) Patch Layers Complete

- [ ] Branding patch complete (name, resources, app metadata).
- [ ] Icon patch complete (all platform-specific assets and wiring).
- [ ] Omnibox UI patch complete (profile badge in front of URL bar).
- [ ] Search/keyword patch complete (default engine + input parsing behavior).
- [ ] First-run/profile defaults patch complete (clean defaults for BugLogin flow).
- [ ] Browser adapter contract points are complete and documented.

## 4) Pre-Build Validation (No Full Build Required)

- [ ] Patchset applies cleanly on frozen Chromium ref.
- [ ] Required resource files exist and paths are correct.
- [ ] Metadata files pass sanity checks (names, identifiers, icon references).
- [ ] Search/default preference templates pass sanity checks.

## 5) Release Acceptance Criteria Frozen

- [ ] Browser launches with isolated profile (`--user-data-dir`).
- [ ] Omnibox search routes correctly (normal query => search, URL => navigate).
- [ ] Profile badge appears correctly in omnibox.
- [ ] Branding and icon are correct in app UI and executable bundle.
- [ ] No dependency on old BugLogin runtime hacks for core browser behavior.

## 6) Final Review Gate

- [ ] Diff reviewed against this checklist.
- [ ] No new features are added after freeze.
- [ ] Only blocker fixes are allowed before release build.

## 7) One-Shot Release Build

- [ ] Trigger release workflow for `macos-arm64` + `windows-x64`.
- [ ] Artifact packaging is runtime-only and verified.
- [ ] Build logs are archived for traceability.

## 8) Post-Build Verification and Publish

- [ ] Smoke test macOS arm64 artifact.
- [ ] Smoke test Windows x64 artifact.
- [ ] Tag release and publish artifacts.
- [ ] Record known gaps for next batch (no immediate hot-loop rebuild unless blocker).

## Notes

- Batch fixes together; avoid one-off rebuilds.
- If a blocker is found, collect related fixes into one patch batch before rerunning release build.
