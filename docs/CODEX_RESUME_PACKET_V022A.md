# Codex Resume Packet — MACHI LOOP v0.22A

Status: Resume-safe handoff while Codex capacity is unavailable
Created: 2026-08-26
Updated: 2026-08-27 after outage-safe preparation completed
Remote canonical repository: `48wr9f4wgp-lab/machi-loop`
Remote baseline intentionally preserved: `main` at `1065b4f9337cfff47b088c9884c1bef8f3001f54`

> Important: do not guess the Codex local base SHA. On resume, inspect local state before any sync operation.

## 1. Reserved v0.22A scope — do not overwrite

Codex has a locally implemented, locally tested, but uncommitted/unpushed v0.22A Feedback Pass.

### New local files reported by Codex
- `feedback/feedback_settings.gd`
- `feedback/audio_feedback.gd`
- `feedback/haptics_adapter.gd`
- `feedback/feedback_controller.gd`
- `main_v22_feedback.gd`
- `tests/feedback_controller_test.gd`
- `tests/feedback_integration_test.gd`
- `tests/feedback_save_migration_test.gd`

### Modified local files reported by Codex
- `main.gd`
- `VERSION`
- `README.md`
- `assets/jp_charset.txt`
- `tests/save_fixture_test.gd`
- `tests/legacy_save_migration_test.gd`
- `tests/functional_build_regression_test.gd`
- `.github/workflows/deploy-pages.yml`

Do not create competing remote edits to these paths before recovery.

## 2. Reported v0.22A behavior

- Distinct runtime PCM16 SFX for arterial commit, goal complete, city tier up, widen, bulldoze, insufficient cash.
- Event cooldown and same-batch de-duplication.
- Deterministic road → goal → tier reward feedback order.
- Haptics abstraction with light/medium/strong semantics.
- Web/Windows/unknown platform vibration path safely no-ops.
- SFX/Haptics settings UI.
- Save schema 6 with `feedback_settings` persistence and old-save defaults.
- Existing save checksum/backup/corruption recovery/migration retained.
- Existing simulation/domain balance reported unchanged.

## 3. Reported local verification

Godot 4.7.2:
- validate: pass
- runtime smoke: pass
- existing fixtures: 12/12 pass
- new Feedback fixtures: 3/3 pass
- Functional Build regression: pass
- correct first-road balance: `700 - 6*12 + 80 = 708`
- render fixture: pass, reported geometry=69
- save migration/recovery: pass
- Web export: pass
- local browser run: pass
- browser console: 0 warnings / 0 errors

Expected/non-blocking observations:
- intentionally corrupted-save fixtures emit JSON parse failure before successful recovery
- some pre-existing FTUE shutdown RID/Object/Resource warnings
- short editor validate may emit shutdown scan/StringName warnings
- stale local browser Service Worker state may request obsolete `/sw.js?v=20`

## 4. Items still unverified for v0.22A

- actual GitHub Actions on the v0.22A diff
- GitHub Pages deployment
- iPhone physical haptic feel
- Android physical haptic behavior and permission configuration
- native iOS/Android package generation
- speaker/headphone subjective SFX quality

## 5. Resume Merge Gate

Do not `reset --hard`, `clean`, or blindly `pull`.

Required order:
1. `git status`
2. `git branch --show-current`
3. `git log -1 --oneline`
4. `git diff --stat`
5. full `git diff`
6. preserve local v0.22A using a WIP commit/patch/stash if needed
7. only then `git fetch`
8. compare local base with remote `main`
9. confirm remote main is still the intentional shared baseline or explicitly review any newer remote change
10. reconcile without reimplementing/overwriting local v0.22A
11. re-run validate → runtime → all fixtures → save/migration/recovery → Functional regression → render → Web export
12. commit/push v0.22A to a feature branch
13. open PR
14. require GitHub Actions green
15. merge only after green
16. require Pages deployment green
17. perform iPhone PWA smoke before closing v0.22A

## 6. Outage-safe Draft PR inventory

All remain draft/unmerged. `main` has intentionally not been advanced.

### PR #29 — `docs/v022b-planning`
Planning/resume package:
- this Resume Packet
- Analytics Event Dictionary
- Performance Budget
- Native requirements
- Production Audio/Haptics target
- Integration-to-RC Master Plan

### PR #30 — `feat/analytics-foundation-v022b`
- versioned analytics schema
- strict property/type/enum validation
- PII key rejection
- no-network/no-disk adapter
- analytics controller
- performance-summary rate guard
- dedicated Analytics CI green
- existing full MACHI LOOP CI green

### PR #31 — `feat/performance-foundation-v022b`
- P0-P5 named states
- bounded 1200-frame monitor
- avg/p95/worst/slow-frame metrics
- sustained sub-30fps detector
- >=100 ms interaction-stall detector
- analytics-ready bands
- dedicated Performance CI green
- existing full MACHI LOOP CI green

### PR #32 — `chore/release-readiness-gates-v1`
- release-readiness static audit
- signing/secret/local-path hygiene
- safer `.gitignore` for native signing artifacts
- QA Matrix
- Accessibility Gate
- Localization Gate
- Data/Privacy Inventory
- Store Compliance snapshot
- Final Audit Scorecard
- RC Execution Plan
- Store listing draft
- Privacy Policy draft
- third-party license inventory
- external approval gates
- Native preflight tool
- Codex Native task packet
- Codex RC fix-only task packet
- current mobile-city-builder benchmark
- Analytics/Observability provider ADRs
- latest branch head static release audit: green
- latest branch head existing full MACHI LOOP CI: green

### PR #33 — `feat/observability-foundation-v1`
- strict severity/error-code/context validation
- explicit PII/secret rejection
- bounded 32-entry breadcrumb ring
- no-network/no-disk crash reporter adapter
- dedicated Observability CI green
- existing full MACHI LOOP CI green

## 7. Post-v0.22A integration order

Do not merge stale outage branches blindly. Rebase/review one at a time after v0.22A is safely on main.

Recommended order:
1. PR #32 — repository/release tooling first
2. PR #30 — Analytics foundation
3. PR #31 — Performance foundation
4. PR #33 — Observability foundation
5. PR #29 — planning docs last, so references match final merged state

A different order is allowed only if a concrete conflict/dependency makes it safer.

## 8. Remaining implementation after foundation merge

Only thin runtime connection is intended. No new product features.

### Analytics
Connect meaningful events only:
- session
- FTUE
- arterial/widen/bulldoze
- meaningful blocked action
- goal/tier/district progression
- policy/service changes
- feedback setting changes
- save/migration/recovery outcome
- bounded performance summary

Provider remains no-op until separately approved.

### Performance
Connect:
- startup-to-interactive
- frame sampling
- road interaction latency
- geometry/tier context
- P1/P3/P5 measurement states

Do not optimize before measurement.

### Observability
Connect bounded semantic breadcrumbs around:
- session ready
- save/load/migration/recovery
- road actions
- progression transitions
- strategy changes
- internal recoverable/fatal errors

Never log full save payload, free-form user data, file-system user paths, raw identifiers, tokens, or secrets.

## 9. Native and physical-device work

Android:
- run Native preflight
- verify JDK/Android SDK tooling
- add Android export configuration using then-current Play requirements
- add required haptic permission only if needed by final path
- development signing only until distribution approval
- build/install/test on physical Android

Android device gate:
- boot/resume
- save/reload
- haptics
- SFX
- P1/P3/P5 performance
- background/foreground lifecycle

Native iOS:
- requires appropriate macOS/Xcode environment
- export Godot iOS project
- development signing only until distribution approval
- physical iPhone test

Native iPhone gate:
- boot/resume
- save/reload
- real haptic semantics
- speaker/headphone SFX
- P1/P3/P5 performance
- lifecycle interruption recovery

## 10. Final phase

After real-device baselines:
1. Final Audit
2. feature freeze
3. fix-only stabilization
4. full regression
5. repeat device case that found each issue
6. no P0/P1 findings
7. all hard gates pass
8. RC handoff

Use `docs/INTEGRATION_TO_RC_MASTER_PLAN_V1.md` as the complete execution sequence and `docs/CODEX_RC_TASK_PACKET_V1.md` for the fix-only phase after PR #32 is merged.

## 11. Explicitly forbidden without user approval

- public release
- Store submission/publication
- production pricing activation
- paid provider/service contract
- distribution signing credential changes/publication
- destructive production/user data operation

No outage-safe branch should be reimplemented inside the local v0.22A branch.
