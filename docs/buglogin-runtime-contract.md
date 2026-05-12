# BugLogin Runtime Contract

Bugmax is built for BugLogin-managed profiles.

## Launch environment

BugLogin should set:

```bash
BUGLOGIN_PROFILE_NAME="Profile A"
```

`BUGMAX_PROFILE_NAME` is accepted as a compatibility fallback.

## Launch flags

BugLogin should continue to own profile isolation and proxy configuration:

```bash
--user-data-dir=/absolute/profile/path
--proxy-server=host:port
--remote-debugging-port=0
--no-first-run
```

## Included source customizations

- BugLogin/Bugmax Chromium branding.
- Generated Bugmax product icons.
- macOS bundle id `com.buglogin.bugmax`.
- Omnibox profile badge from `BUGLOGIN_PROFILE_NAME`.
- Search-biased multi-token omnibox input.
- BugLogin first-run marker pref.

## Fingerprint scope

Deep fingerprint behavior requires pinned source patches after the first
BugLogin-branded build completes on the Mac mini. This repo does not reuse
CloakBrowser binaries or proprietary patch logic.
