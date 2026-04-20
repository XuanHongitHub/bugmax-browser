# Build Notes

This repository builds Chromium from source using depot_tools in GitHub Actions.

Design choices:
- Runtime-only artifact packaging to reduce output size.
- Split job per platform target.
- Optional `smoke` mode for fast validation.
- Customization layer is applied once before build via scripts and patchset.

Known constraints:
- Full Chromium builds are resource and time intensive.
- Pinned refs improve reproducibility.
- Omnibox profile badge and deep UI behavior require explicit Chromium source patches in `patches/chromium/`.

## One-shot flow

1. Freeze scope and Chromium ref.
2. Add all Bugmax patches under `patches/chromium/`.
3. Ensure `config/initial_preferences.json` matches desired search behavior.
4. Trigger `.github/workflows/build-bugmax.yml` manually with:
   - `build_profile=full`
   - `macos_targets=arm64-only` (or `arm64-and-x64` for release)
   - `apply_customizations=true`
