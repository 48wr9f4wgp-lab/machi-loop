# MACHI LOOP — Integration to RC Master Plan v1

Status: Canonical execution sequence after the Codex outage-safe preparation work
Purpose: reduce remaining work to integration, real-environment verification, final audit, and fix-only stabilization

## Non-negotiable rule

Do not modify, overwrite, reset, clean, or reimplement the locally completed but unpushed v0.22A Feedback Pass before its recovery gate is complete.

No public release, Store submission, paid service contract, monetization activation, signing-key publication, or destructive data operation is authorized by this plan.

## Current remote baseline

- Canonical remote `main` intentionally remains at `1065b4f9337cfff47b088c9884c1bef8f3001f54` until v0.22A local work is recovered.
- Outage-safe work exists only on draft branches/PRs.

## Draft PR inventory

### PR #29 — Planning / resume packet
Branch: `docs/v022b-planning`
Contains:
- Codex Resume Packet
- Analytics Event Dictionary
- Performance Budget
- Native requirements
- Production Audio/Haptics target
- this master sequence

### PR #30 — Analytics foundation
Branch: `feat/analytics-foundation-v022b`
State before integration:
- provider-agnostic schema/controller/no-op adapter
- explicit PII rejection
- dedicated CI green
- existing full MACHI LOOP CI green

### PR #31 — Performance foundation
Branch: `feat/performance-foundation-v022b`
State before integration:
- P0-P5 named states
- bounded 1200-frame monitor
- avg/p95/worst/slow-frame metrics
- hard-regression detectors
- dedicated CI green
- existing full MACHI LOOP CI green

### PR #32 — Release readiness
Branch: `chore/release-readiness-gates-v1`
State before integration:
- static release audit
- signing/secret/path hygiene
- QA/Accessibility/Localization/Privacy/Store/RC gates
- Native preflight
- Store copy/privacy/license drafts
- dedicated release-readiness CI green on latest branch head
- existing full MACHI LOOP CI green on latest branch head

### PR #33 — Observability foundation
Branch: `feat/observability-foundation-v1`
State before integration:
- bounded breadcrumbs
- privacy-safe error schema
- no-op crash reporter
- dedicated CI green
- existing full MACHI LOOP CI green

## Phase 1 — Recover and merge v0.22A

This phase must happen first.

1. Inspect local repository:
   - `git status`
   - `git branch --show-current`
   - `git log -1 --oneline`
   - `git diff --stat`
   - full `git diff`
2. Preserve local v0.22A work before any synchronization.
3. `git fetch` only after preservation.
4. Verify local v0.22A still contains the reported Feedback Pass and no unrelated edits.
5. Re-run local validation:
   - Godot validate
   - runtime smoke
   - all existing fixtures
   - all Feedback fixtures
   - save/migration/recovery
   - Functional Build regression
   - 3D renderer
   - Web export
6. Commit v0.22A to a dedicated branch.
7. Push and open PR.
8. Require GitHub Actions green.
9. Merge v0.22A.
10. Require Pages deployment green.
11. iPhone PWA smoke:
    - Japanese font
    - settings UI
    - SFX toggle
    - Haptics toggle persistence
    - existing city save intact

Do not proceed if any save, migration, progression, or runtime regression exists.

## Phase 2 — Rebase and merge outage-safe foundations

After v0.22A is on `main`, process PRs one at a time. Never merge stale branches blindly.

Recommended dependency order:

1. PR #32 Release readiness
   - mostly tooling/docs and repository hygiene
   - rebase against post-v0.22A `main`
   - resolve `.gitignore` and workflow conflicts carefully
   - static CI + full CI must be green

2. PR #30 Analytics foundation
   - rebase
   - no provider SDK yet
   - dedicated CI + full CI green

3. PR #31 Performance foundation
   - rebase
   - dedicated CI + full CI green

4. PR #33 Observability foundation
   - rebase
   - dedicated CI + full CI green

5. PR #29 Planning docs
   - rebase last so documentation references final merged state accurately

A different order is permitted only when an actual merge conflict or dependency proves it safer.

## Phase 3 — Thin runtime integration

After all foundations are merged, create one integration branch. Do not add new product features.

### Analytics connection
Connect only meaningful state transitions:
- session start/end
- FTUE start/step/complete
- successful arterial commit
- widen / bulldoze
- meaningful blocked action
- city goal complete
- city tier up
- district unlock
- policy change
- service toggle
- feedback setting change
- save write failure/recovery/migration result
- one bounded performance summary per defined session/checkpoint

Rules:
- no simulation-tick event spam
- no arbitrary free-form properties
- no PII
- provider remains no-op until explicitly approved
- analytics failure must never block play/save

### Performance connection
Measure without changing game balance:
- startup-to-interactive duration
- frame sampling
- critical road interaction latency
- geometry count where reliable
- city tier
- named P1/P3/P5 measurement state

Do not optimize during instrumentation implementation.

### Observability connection
Record only bounded semantic breadcrumbs around:
- session ready
- save/load/migration/recovery
- arterial commit/widen/bulldoze
- goal/tier transition
- service/policy change
- fatal or recoverable internal failures

Do not log full save data, user-entered text, file-system user paths, device identifiers, tokens, or secrets.

### Integration gate
Required before merge:
- all old fixtures green
- Feedback fixtures green
- Analytics fixtures green
- Performance fixtures green
- Observability fixtures green
- Release-readiness static audit green
- Functional Build regression green
- Save migration/recovery green
- render fixture green
- Web export green

## Phase 4 — Native packaging and real-device verification

### Android
Use the then-current Godot/Google Play requirements, not stale assumptions.
Required work:
- run `tools/native_preflight.py`
- install/verify required JDK and Android SDK tooling
- create Android export configuration
- package identifier/versioning
- VIBRATE permission if required by chosen haptic path
- debug/dev signing only until release signing is explicitly approved
- build and install on physical Android device

Verify:
- boot/resume
- save/reload
- haptic light/medium/strong semantics
- SFX speaker behavior
- P1/P3/P5 performance
- background/foreground recovery

### iOS
Actual iOS build/sign/install requires appropriate macOS/Xcode environment.
Required work:
- export Godot iOS project
- open/build with supported Xcode/iOS SDK
- use development signing only until distribution approval
- install on physical iPhone

Verify:
- boot/resume
- save/reload
- haptic semantics
- SFX speaker/headphone behavior
- P1/P3/P5 performance
- lifecycle interruptions

Web/PWA success must not be treated as native readiness.

## Phase 5 — Real-device performance baseline

Run deterministic/repeatable states:
- P1_FTUE: >=5 min
- P3_MID: >=10 min
- P5_METRO: >=10 min

Record:
- device / OS / build type
- avg FPS
- p95 frame time
- worst frame
- slow-frame rate
- sustained sub-30fps periods
- critical interaction stalls
- startup time
- thermal observation
- crash/reload/OOM

Hard regression candidates:
- sustained <30 FPS for >=5 sec in normal play
- critical road interaction >=100 ms
- reproducible OOM/reload/crash
- save/lifecycle corruption

Only after measurement may optimization begin.

## Phase 6 — Audio/Haptics production decision

v0.22A runtime PCM is a functional placeholder until real-device listening proves otherwise.

Audit:
- road commit must be light/fast, not fatiguing
- goal completion medium reward
- tier-up clearly strongest
- no duplicate reward cacophony
- speaker volume acceptable
- headphones not harsh
- no first-use frame hitch
- no unbounded audio nodes

Replace/generated SFX only if quality/performance evidence justifies it.

## Phase 7 — Provider approval gate

Default runtime remains provider-free/no-op until an explicit decision.

Before adding analytics/crash SDK:
- verify current SDK stability for exact Godot version
- review privacy policy and Store disclosures
- review bundle/performance cost
- review free/paid limits
- review data retention/export/delete behavior
- confirm no account or direct PII is required

Candidate recorded in ADRs; no contract/account/paid activation is authorized by this plan.

## Phase 8 — Final Audit

Feature freeze begins here.

Run `docs/FINAL_AUDIT_SCORECARD_V1.md` and all hard gates.

Minimum audit domains:
- Core Loop
- FTUE
- UI/UX / safe areas / one-hand touch
- Art / hierarchy / readability
- Motion/VFX
- Audio/Haptics
- Progression
- Economy/traffic/service recovery
- Save/migration/recovery
- Accessibility
- Localization
- Performance/thermal
- Analytics/Observability privacy
- QA/regression
- Store/compliance/license readiness

Any P0/P1 or hard-gate failure blocks RC.

## Phase 9 — Fix-only stabilization

Use `docs/CODEX_RC_TASK_PACKET_V1.md`.

Rules:
- no new features
- no speculative refactor
- fix highest-severity confirmed finding first
- one bounded change at a time
- run relevant focused fixture then full regression
- re-run device case that found the bug
- update audit score/evidence

Exit only when:
- no P0/P1 findings
- all hard gates pass
- save/migration confidence is high
- target-device performance passes
- Store/privacy/license checklist is consistent with final binary

## Phase 10 — Release Candidate handoff

At this point only external/irreversible approvals should remain:
- final provider/account decisions if any
- distribution signing credentials
- final price
- Store listing final text/screenshots
- Store submission/publication

Those require explicit user approval.

## Definition of preparation complete

Preparation work is considered complete now when all tasks not requiring the unavailable Codex local v0.22A state, a physical device, platform-native build environment, provider account, signing credentials, or external Store action have been performed or specified with an executable acceptance gate.
