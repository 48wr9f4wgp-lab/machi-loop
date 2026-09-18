# AXIVA — Vertical Slice / Device Validation Gate Audit

Date: 2026-09-19 JST  
Scope: title-local gate/evidence record  
Authority basis: GAME_DEV_MASTER_RULES v2.4 + AXIVA GDD v2.0 + SUCCESS_DEFINITION_V2 + VERTICAL_SLICE_V2_SPEC + AXIVA ART BIBLE v1.0  
Audited working state: `main@652bce13bdbb198f446e714f11fd1b05758768a3`  
PRODUCTION_DECISION: `UNDECIDED`  
RELEASE_APPROVAL: `NOT_REQUESTED`

## 1. Executive verdict

**GREENLIGHT is not ready to start yet.**

AXIVA has passed the major component demonstrations of the Vertical Slice on physical iPhone/Web preview, including first-road growth, touch/portrait presentation, renderer stability, map expansion, and congestion -> bypass -> recovery.

However, the title-specific Vertical Slice exit rule requires **one physical iPhone run that demonstrates the complete sequence end-to-end**:

`empty land -> first road -> city born -> visible growth -> structural congestion -> player intervention -> visible recovery/reconfiguration`

That single uninterrupted fresh-to-recovery run has not yet been captured/verified.

In addition, GAME_DEV_MASTER_RULES v2.4 requires broader DEVICE_VALIDATION coverage before GREENLIGHT: lifecycle, save/load on device, cold launch, suspend/resume/interruption, frame pacing, thermal/battery tendency, and resource-dead-end checks across multiple sessions. Those are not yet fully evidenced.

Therefore the correct macro phase remains **VERTICAL_SLICE**, with device-validation activities allowed as supporting work. Do not mark DEVICE_VALIDATION exited and do not set PRODUCTION_DECISION until these gaps are closed.

## 2. Evidence already established

### Automated / repository evidence
- Current main: `652bce13bdbb198f446e714f11fd1b05758768a3`.
- PR #71 v0.37 Recovery Device Test: all six PR-head checks passed before merge.
- Main push checks for the same merge completed successfully:
  - Release readiness static checks
  - Observability foundation checks
  - Build and deploy AXIVA
- Existing dedicated fixtures cover first-road/growth presentation, congestion recovery, fresh mode, device-stability renderer behavior, incremental renderer, reset, mobile HUD/font, road drawing/map scale, expansion camera/reveal, and the recovery device-test fixture.

### Physical iPhone evidence
- Fresh-run recording (2026-09-18, ~87.1 s) established:
  - fresh start / first-road flow;
  - visible autonomous city growth;
  - portrait HUD/readability improvements;
  - straight road input;
  - 12 -> 14 -> 16 map-width progression;
  - no recurrence of the old persistent ~0.85 s whole-city twitch.
- v0.36.1 expansion reveal was user-validated on device as OK after the unlock-frame snap fix.
- v0.37 `?recovery=1` was user-validated on device as OK for the congestion -> bypass -> recovery -> resumed-growth component sequence.

These are valid component-level device proofs. They are **not** equivalent to the required single full fresh-to-recovery Vertical Slice run.

## 3. SUCCESS_DEFINITION_V2 gate audit

| Gate | Status | Evidence / gap |
|---|---|---|
| Core Experience Success | PARTIAL | First road, autonomous response and recovery components work on device; full fresh-player sequence through the structural problem has not been verified in one run. |
| Growth Delight | PASS (slice component) | Physical fresh-run evidence shows rapid visible growth, local-road/building/vehicle response and city-birth presentation. External/naive-player delight is not yet measured. |
| Causality Readability | PARTIAL | Road -> growth and congestion -> bypass -> recovery are individually readable on device; end-to-end comprehension in one fresh session remains unverified. |
| Decision Density | PARTIAL | The slice produces meaningful interventions, but the target timing for the first structural problem (2–5 min) and the complete problem -> recovery loop (<=8 min) has not been timed in one fresh run. |
| Recovery Gate | PASS (component) | `?recovery=1` physically verified severe/no-redundancy congestion, player bypass intervention, visible recovery and resumed growth. |
| Smartphone Product Visual | PASS for current slice direction | City-dominant portrait presentation, HUD placement/readability and map framing were physically reviewed; this is not a final-polish/store-art claim. |
| Technical Gate | PARTIAL | Import/tests/export/deploy are green; physical touch/framing/stability are proven. Full first-road -> problem -> recovery physical run and broader device-performance/lifecycle evidence remain incomplete. |

## 4. GAME_DEV_MASTER_RULES v2.4 — VERTICAL_SLICE Exit

| Requirement | Status |
|---|---|
| Representative one-session experience is playable | PARTIAL — components are playable, but the required full single-session proof is missing |
| Core Loop established | PASS |
| Main controls work for iPhone/touch | PASS |
| Main Core Game Feel can be evaluated | PASS |
| Visual Target direction can be evaluated | PASS |
| Major technical risks known with mitigation/decision | PASS for currently discovered renderer/input risks |
| Build can enter DEVICE_VALIDATION | PASS |

**Overall VERTICAL_SLICE Exit: NOT YET PASSED.**

Hard blocker: one uninterrupted physical iPhone `?fresh=1` run demonstrating the complete golden path through recovery.

## 5. GAME_DEV_MASTER_RULES v2.4 — DEVICE_VALIDATION audit

| Device-validation item | Status |
|---|---|
| Touch feel | PASS / current slice |
| UI size / safe area / readability | PASS / current slice |
| One-hand / gesture friction | PARTIAL — road drawing improved; systematic one-hand pass not logged |
| Core Loop understanding speed | PARTIAL — developer/user test evidence only |
| Desire to replay / continue | UNVERIFIED |
| Reward / growth recognition | PASS / current slice |
| Failure -> retry / recovery | PASS for structural recovery component |
| FPS / frame pacing | PARTIAL — frame-stability issue closed; target-FPS profiling not completed |
| Thermal tendency | UNVERIFIED |
| Battery tendency | UNVERIFIED |
| Load behavior | PARTIAL — launch works; no explicit load-time/device budget recorded |
| Save / load on physical device | UNVERIFIED as a dedicated device check |
| Cold launch | PARTIAL — used in testing, not logged as a dedicated repeated check |
| Suspend / resume | UNVERIFIED |
| Interruption recovery | UNVERIFIED |
| Progression blocker / resource dead-end | PARTIAL — no current blocker observed; normal-session economy dead-end has not been deliberately challenged |
| Representative physical iPhone display/input | PASS |

**Overall DEVICE_VALIDATION Exit: NOT PASSED.**

## 6. Minimum work before GREENLIGHT

### Hard blocker A — full Vertical Slice run
On physical iPhone, use normal fresh mode and capture one uninterrupted run:

`?fresh=1`

Record at minimum:
- control available -> first meaningful input;
- road commit -> first visible autonomous response;
- first recognizable settlement;
- first meaningful structural congestion;
- player intervention;
- visible recovery/reconfiguration;
- whether total problem -> recovery time stays within the <=8 min target.

The run must use the real progression, not the seeded `?recovery=1` shortcut.

### Hard blocker B — device-validation pack
Across multiple physical-device sessions, explicitly check:
- cold launch;
- save -> close -> reload;
- suspend/background -> resume;
- at least one interruption/re-entry path available on the test device;
- frame pacing during dense growth/recovery;
- thermal and battery tendency during a longer session;
- normal-session recovery from low cash / poor road structure without an unrecoverable dead end.

### GREENLIGHT preparation after A/B
Prepare the decision record required by Master v2.4:
- riskiest assumption;
- observation/measurement method;
- GO condition;
- HOLD condition;
- additional validation time/budget ceiling;
- physical/playtest evidence;
- current technical risk;
- remaining production cost/content volume;
- known blockers;
- decision owner/date.

A short explanation-free playtest by a player who did not build the game is strongly recommended before GO because the riskiest remaining product assumption is comprehension/delight, not raw mechanical execution.

## 7. Documentation drift found by this audit

These are not runtime blockers, but they are retrieval/state risks and should be reconciled before GREENLIGHT:

1. `DEV_STATUS.json` still says `Release Readiness / 実機QA`, which is incompatible with the current Pre-GO Vertical Slice state.
2. `docs/PRODUCT_LOCK_V1.md` still describes iOS / Android as primary platforms. Project Hard Locks are higher authority: iPhone/iOS is the active development target and Android is deferred until post-GO `PLATFORM_EXPANSION_DECISION`.
3. `README.md` still says `Landscape touch-first UX`, conflicting with the locked portrait direction.
4. `README.md` / `VERSION` still describe the older 0.22A-era build and should not be used as phase truth.

Until reconciled, phase/platform decisions must follow Project Hard Locks + GDD v2 + this evidence record, not those stale lines.

## 8. Next gate action

**NEXT:** run and record the full `?fresh=1` golden path on physical iPhone from empty land through congestion intervention and visible recovery.

No App Store submission, production signing, paid service, or other release-enablement action is authorized by this audit.
