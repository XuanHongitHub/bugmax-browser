# Bugmax One-Shot Custom Plan (2026-04-20)

## Status

- [x] Freeze workflow to manual-only release execution.
- [x] Add pre-build guard to block release when required patch set is incomplete.
- [x] Add one-shot spec/plan records for team alignment.
- [ ] Implement Chromium patch files (`001/010/020/030`) against pinned ref.
- [ ] Run single release build after patch completion.

## Execution notes

- Existing long-running builds were canceled to avoid violating one-shot policy.
- Next build is allowed only after the required patch set exists and is non-empty.
