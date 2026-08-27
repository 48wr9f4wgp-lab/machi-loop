# MACHI LOOP — Codex Outage PR Index v1

Updated: 2026-08-26
Canonical remote main intentionally remains at the pre-v0.22A shared baseline until Codex local recovery is complete.

## Hard rule

Do not merge any outage PR before the locally implemented v0.22A Feedback Pass is preserved, pushed, CI-green, merged, Pages-deployed, and iPhone PWA-smoked.

Do not reimplement outage PR contents in the v0.22A local branch.

## PR inventory

### PR #29 — Planning / Resume
Branch: `docs/v022b-planning`
Purpose:
- v0.22A Resume Packet;
- analytics event dictionary;
- performance budget;
- native requirements;
- production Audio/Haptics target;
- this outage index.

Conflict risk: low; documentation only.

### PR #30 — Analytics foundation
Branch: `feat/analytics-foundation-v022b`
Observed head: `073e0599891d82106f705aebf6939909521be084`
Status before resume: dedicated Analytics CI green; existing full MACHI LOOP CI green.
Purpose:
- strict versioned event schema;
- PII/property validation;
- no-op/no-network adapter;
- provider-independent controller;
- tests/isolated CI.

Conflict risk with v0.22A: low by design; still rebase after v0.22A because main VERSION/runtime layer will have moved.

### PR #31 — Performance foundation
Branch: `feat/performance-foundation-v022b`
Observed head: `0f53e63e9fbc5cb00d46ebbd69b59e84b748855d`
Status before resume: dedicated Performance CI green; existing full MACHI LOOP CI green.
Purpose:
- P0–P5 state vocabulary;
- bounded 1200-frame monitor;
- avg/p95/worst/slow-frame metrics;
- hard-regression thresholds;
- tests/isolated CI.

Conflict risk with v0.22A: low; runtime connection is deliberately absent.

### PR #32 — Release readiness / audit
Branch: `chore/release-readiness-gates-v1`
Purpose:
- static secret/signing/local-path audit;
- `.gitignore` hardening;
- final audit scorecard;
- QA/accessibility/localization/privacy matrices;
- Store requirement snapshot;
- native/RC Codex Task Packets;
- live city-builder benchmark refresh;
- Analytics/Observability ADRs;
- Store listing/privacy drafts;
- license inventory;
- native environment preflight tool.

Status: draft. Existing full game CI is expected to remain green; dedicated release-readiness CI must be checked on the latest head after the audit self-detection fix.

Conflict risk: low; no reserved v0.22A gameplay/save/feedback files intentionally changed. `.gitignore` and new workflow/docs/tools require normal rebase review.

### PR #33 — Observability foundation
Branch: `feat/observability-foundation-v1`
Observed head: `ae00f184cda5f5908018cb9f427eb8e062722b04`
Status before resume: dedicated Observability CI green; existing full MACHI LOOP CI green.
Purpose:
- privacy-safe error schema;
- 32-entry bounded breadcrumbs;
- no-op reporter;
- tests/isolated CI.

Conflict risk: low; no gameplay/runtime integration yet.

## Recommended post-v0.22A integration order

After v0.22A is merged and deployed:

1. Fetch all remote branches/PRs.
2. Rebase/reconcile **PR #32** first only if its static audit/docs/tools remain clean against v0.22A. It supplies the safety gates for later integration.
3. Rebase/reconcile **PR #30 Analytics foundation**; run dedicated + full CI; merge.
4. Rebase/reconcile **PR #31 Performance foundation**; run dedicated + full CI; merge.
5. Rebase/reconcile **PR #33 Observability foundation**; run dedicated + full CI; merge.
6. Rebase/reconcile **PR #29 documentation** last; remove stale duplicate/outdated wording during review and merge only the still-canonical docs.
7. Create a fresh integration branch from updated main to connect Analytics/Performance/Observability to the v0.22A runtime. Do not perform this wiring inside the historical foundation PRs unless the diff is trivial and reviewable.
8. Full CI + Web/PWA actual behavior.
9. Native task packet.
10. RC task packet / fix-only cycle.

## Why foundations are separate

The outage PRs intentionally stop before touching `main_v22_feedback.gd`, save schema 6, feedback settings, or deploy-pages modifications. This allows Codex to recover its local work without a remote merge conflict and makes each foundation independently revertible.

## Merge Gate after every outage PR

For each:
- inspect diff against current main;
- resolve stale assumptions;
- dedicated tests green;
- existing full game CI green;
- no reserved/local work overwritten;
- no provider/network/Store external action introduced accidentally.
