# Build Notes

This repository builds Chromium from source using depot_tools in GitHub Actions.

Design choices:
- Runtime-only artifact packaging to reduce output size.
- Split job per platform target.
- Optional `smoke` mode for fast validation.

Known constraints:
- Full Chromium builds are resource and time intensive.
- Pinned refs improve reproducibility.
