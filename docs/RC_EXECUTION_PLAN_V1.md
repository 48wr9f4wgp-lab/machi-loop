# MACHI LOOP — Release Candidate Execution Plan v1

Status: Release Readiness

## Goal
Arrive at a Release Candidate where remaining work is audit findings and fixes only, not new system design.

## Preconditions
- v0.22A Feedback integrated and CI-green.
- Analytics, Performance and Observability foundations integrated behind safe adapters.
- No known save migration gap.

## Sequence
1. **Functional verification** — new game, FTUE, road/growth, demand, traffic, economy, policies/services, all tiers, save/relaunch, migration/recovery.
2. **Web/PWA device verification** — iPhone P1/P3/P5, settings, Japanese glyphs, safe areas, cache/update, thermal/performance.
3. **Android native** — toolchain, current target API, install, signed release artifact validation, permissions, lifecycle, feedback, performance.
4. **iOS native** — macOS/Xcode export, signing/install, safe areas, lifecycle/save, feedback, performance.
5. **Accessibility/localization** — sound/haptics off, grayscale, touch targets, Reduced Motion decision, Japanese LQA, pseudo-localization if needed.
6. **Privacy/security/compliance** — SDK inventory, permissions/entitlements, static audit, analytics schema, privacy policy, current Store requirements.
7. **Visual/Game Feel audit** — use FINAL_AUDIT_SCORECARD_V1.md; require score 90+ and no Hard Gate.
8. **Fix-only cycle** — reproduce → smallest fix → targeted test → regression → device re-check → close.
9. **Candidate freeze** — version/SHA/artifact/release notes/rollback path/final audit.

No new feature enters scope after functional verification unless it fixes a Hard Gate.

## Explicitly not automatic
Public release, Store submission, paid sale activation, external service contracts and irreversible production rollout require explicit user approval after the candidate is ready.
