# Chromium patch checklist

Before one-shot release build, include all required patches here.

Minimum expected patches for Bugmax:

- `001-branding.patch`: product name, identifiers, branding strings.
- `010-omnibox-profile-badge.patch`: profile badge in omnibox.
- `020-search-defaults.patch`: omnibox URL/query behavior and default search provider.
- `030-first-run-defaults.patch`: first-run/profile defaults aligned with BugLogin.

If a patch is intentionally skipped, document it in `docs/release-one-shot-checklist.md` before build.
