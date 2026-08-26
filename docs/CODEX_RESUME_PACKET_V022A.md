# Codex Resume Packet — MACHI LOOP v0.22A

Status: Resume-safe handoff while Codex capacity is unavailable
Created: 2026-08-26
Updated: 2026-08-26 after outage-safe v0.22B work
Remote canonical repository: `48wr9f4wgp-lab/machi-loop`
Remote baseline observed when this packet was created: `main` at `1065b4f9337cfff47b088c9884c1bef8f3001f54`

> Important: the exact Codex local base SHA is intentionally not guessed. On resume, read `git status`, `git branch --show-current`, `git log -1 --oneline`, and `git diff` before any sync operation.

## 1. Reserved scope — do not overwrite

Codex has a locally implemented, tested, but uncommitted/unpushed v0.22A Feedback Pass. Until recovery is complete, the following paths are reserved and should not receive competing remote implementation changes:

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

## 2. Reported v0.22A behavior

- Distinct runtime-generated PCM16 SFX for arterial commit, goal complete, city tier up, widen, bulldoze, and insufficient cash.
- Event cooldown, same-batch de-duplication, and deterministic reward ordering.
- Haptics adapter with light/medium/strong semantic mapping.
- Web/Windows/unknown platforms safely no-op for physical vibration.
- SFX and haptics settings UI.
- Save schema advanced to 6 with `feedback_settings` persistence, migration, checksum, backup, corruption recovery, and defaults for old saves.
- Existing simulation balance/domain logic reported unchanged.

## 3. Reported verification state

Reported local verification on Godot 4.7.2:
- Validate: pass
- Runtime smoke: pass
- Existing fixtures: 12/12 pass
- New Feedback fixtures: 3/3 pass
- Functional Build regression: pass
- Expected first-road balance equation: `700 - 6*12 + 80 = 708`
- Render fixture: pass, reported geometry=69
- Save migration/recovery: pass
- Web export: pass
- Local browser run: pass
- Browser console: 0 warnings / 0 errors

Expected/non-blocking observations reported:
- Intentional corrupted-save fixtures emit JSON parse failure before successful recovery.
- Some pre-existing FTUE fixture shutdown RID/Object/Resource warnings remain.
- Short editor validate may emit shutdown-related scan/StringName warnings.
- Old local browser Service Worker state may request obsolete `/sw.js?v=20`; current export does not register that worker.

## 4. Unverified items

- GitHub Actions on the actual v0.22A diff
- GitHub Pages deployment
- iPhone native haptics feel
- Android native haptics and `VIBRATE` permission
- Native iOS/Android packaging
- Speaker/headphone subjective SFX tuning
- Real-device performance instrumentation
- Analytics provider integration

## 5. Resume Merge Gate

On Codex recovery, do not `reset --hard`, `clean`, or blindly `pull`.

Required order:
1. `git status`
2. `git branch --show-current`
3. `git log -1 --oneline`
4. `git diff --stat` and full `git diff`
5. Preserve local work using a WIP commit/patch/stash if necessary.
6. `git fetch`
7. Compare local base and remote `main`; explicitly inspect any remote commits made during the outage.
8. Reconcile without reimplementing or overwriting the v0.22A local work.
9. Re-run validate → runtime → all fixtures → save/migration → functional regression → render → Web export.
10. Only then commit/push v0.22A to a feature branch and open a PR.
11. Require GitHub Actions green before merge.
12. Require Pages deployment and iPhone PWA smoke before closing v0.22A.

## 6. Changes intentionally allowed during Codex outage

Remote work during the outage is limited to non-conflicting planning/documentation and isolated new modules on separate branches, especially:
- v0.22B analytics event dictionary/foundation
- performance measurement/budget/foundation
- native packaging checklist
- production Audio/Haptics quality target
- future Codex Task Packets

No remote code should touch the reserved v0.22A paths until the Merge Gate is complete.

### Outage branches / PRs created

All of the following remain **draft/unmerged** so `main` stays at the original shared baseline while Codex local v0.22A is recovered:

1. PR #29 — `docs/v022b-planning`
   - Resume Packet
   - Analytics Event Dictionary
   - Performance Budget
   - Native Export Requirements (verified 2026-08-26)
   - Production Audio/Haptics Plan
   - latest observed head: `f64782d1ec920c0a5c4ecd9d8ac33e10ecf5e8ca`

2. PR #30 — `feat/analytics-foundation-v022b`
   - versioned analytics event schema
   - strict property/type/enum validation
   - explicit forbidden PII keys
   - default no-network/no-disk adapter
   - analytics controller with common context and one-per-session performance-summary guard
   - dedicated Analytics CI: green
   - existing full MACHI LOOP CI: green
   - latest observed head: `073e0599891d82106f705aebf6939909521be084`

3. PR #31 — `feat/performance-foundation-v022b`
   - P0–P5 named performance states
   - bounded 1200-frame rolling monitor
   - avg/p95/worst frame metrics
   - slow-frame rate
   - sustained sub-30fps hard-regression detector
   - >=100 ms critical input-stall detector
   - analytics-ready performance bands
   - dedicated Performance CI: green
   - existing full MACHI LOOP CI: green
   - latest observed head: `0f53e63e9fbc5cb00d46ebbd69b59e84b748855d`

These branches should be reviewed/rebased only **after** v0.22A is safely committed/pushed and its Merge Gate is complete. Do not reimplement their contents in the Codex local v0.22A branch.

## 7. Queued next work

After v0.22A is safely merged and deployed:
1. Rebase/review PR #29, #30, and #31 against the new main; merge only if still valid.
2. Connect the AnalyticsController to meaningful game events; keep provider no-op until separately approved.
3. Connect PerformanceMonitor to runtime frame/startup/interaction measurement and deterministic P1/P3/P5 states.
4. Capture real-device performance baselines before optimization.
5. Add Android native export configuration targeting the then-current Play requirement (API 36 baseline as of 2026-08-26).
6. Validate Android permission + real-device haptics.
7. Prepare iOS export, then build/test on macOS/Xcode and physical iPhone.
8. Tune/replace placeholder SFX based on real speaker/headphone listening.

Do not start RC-wide performance optimization or large refactors until actual device telemetry identifies a bottleneck.
