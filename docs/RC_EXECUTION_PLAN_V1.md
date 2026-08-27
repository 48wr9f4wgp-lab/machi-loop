# MACHI LOOP — Release Candidate Execution Plan v1

Status: queued after v0.22A merge + v0.22B integration

## Goal

Arrive at a Release Candidate where the remaining work is **audit findings and fixes only**, not new system design.

## Preconditions

- v0.22A Feedback Pass safely recovered from Codex local state, committed, pushed, CI-green, merged, Pages-deployed.
- Analytics foundation reconciled and integrated behind no-op/provider adapter.
- Performance foundation reconciled and integrated without gameplay dependency.
- Production Audio/Haptics device review completed or explicitly scheduled as an RC finding.
- No known save migration gap.

## RC sequence

### RC-0 Merge Gate
1. Preserve Codex local state.
2. Fetch remote.
3. Compare v0.22A against outage PRs.
4. Resolve/rebase deliberately.
5. Full automated regression.

### RC-1 Functional verification
- New game
- FTUE
- main road growth
- demand
- traffic degradation/recovery
- economy pressure/recovery
- policy
- services
- all city tiers
- save/relaunch
- legacy migration
- corruption recovery

No new feature enters scope after this point unless it fixes a Hard Gate.

### RC-2 Web/PWA device verification
- baseline iPhone
- P1_FTUE / P3_MID / P5_METRO
- settings persistence
- Japanese glyphs
- safe areas
- cache/update behavior
- 10–20 minute thermal/performance run

### RC-3 Android native verification
- toolchain verification
- API target current requirement
- APK device install smoke
- signed AAB build validation
- permissions inspection
- save/lifecycle
- haptics/audio
- performance P1/P3/P5

### RC-4 iOS native verification
- macOS/Xcode current minimum
- Godot iOS export
- signing/install
- safe areas/lifecycle/save
- haptics/audio
- performance P1/P3/P5

### RC-5 Accessibility + localization
- sound off
- haptics off
- grayscale/color-state audit
- touch targets
- Reduced Motion decision
- Japanese LQA
- pseudo-localization if English-ready claim remains

### RC-6 Privacy / security / compliance
- final SDK inventory
- final permissions/entitlements
- static secret/path audit
- analytics event schema review
- privacy policy draft/URL readiness
- store privacy/Data safety answers prepared from actual binary behavior
- current store requirement refresh

### RC-7 Visual / Game Feel audit
Use `FINAL_AUDIT_SCORECARD_V1.md`.
- score each category with screenshots/evidence;
- list every deduction as a concrete fix;
- compare against current relevant mobile city-builder references;
- require score 90+ and no Hard Gate.

### RC-8 Fix-only cycle
For each finding:
1. reproduce/evidence;
2. smallest safe fix;
3. targeted test;
4. full relevant regression;
5. device re-check when visual/input/performance-related;
6. close finding.

No opportunistic feature addition.

### RC-9 Candidate freeze
- version/build identifiers fixed;
- final candidate SHA recorded;
- artifact retained;
- release notes drafted;
- rollback/hotfix path documented;
- final audit PASS.

## Explicitly not automatic

Public release, Store submission, paid sale activation, and irreversible production rollout require explicit user approval after the candidate is ready.
