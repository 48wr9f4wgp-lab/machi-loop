# AXIVA ZERO C — Metropolis Gate

Status: WORKING HYPOTHESIS / title-local, not Canonical promotion
Base: main@bf28bdb5dea8e593af81e8ec603d3b7f377bcd2b
Date: 2026-09-21
Activation: `?zero=c` (Web experiment); `-- --zero-c` (local validation).

## Change packet

Goal: in a 5–8 minute iPhone trial, make metropolitan growth depend on useful
road structure. Preserve the satisfying destination-led growth of ZERO B.

Non-goals: production balance, native release, policies, management dashboards,
save migration, replacing the normal/A/B modes, automatic deployment.

Existing behavior: B counts a landmark as connected when any road is adjacent;
its center is decorative, and the legacy traffic model rewards arbitrary cycles.

Minimum specification:
- The three destinations must share an actual arterial component. Disconnected
  fragments do not qualify. Local streets remain autonomous feeder roads.
- Route trips between the three destination ports. A useful alternate route
  must bypass the interior of the primary route, stay reasonably short and
  separate spatially; a tiny unrelated loop earns nothing.
- Traffic load comes from developed districts, accumulates on shared edges,
  and splits across useful alternatives. It drives moving cars and queues.
- Maturity requires actual accessible buildings of the destination's function
  near at least two separate centers, plus sufficient connected city growth.
- Above the large-city threshold, poor structure stops additional development;
  repair restores development. Drawing/removing roads always remains available.
- Metropolis requires all destinations, two mature centers, useful alternatives
  for at least two destination pairs, stable non-severe flow for 12 simulation
  ticks and 40 accessible buildings. Thresholds are prototype tuning only.
- Prevention qualifies: experiencing a congestion failure is never mandatory.
- No score cards: queues, paused construction, resumed growth and district
  densification communicate the state. Only stage and one short contextual cue.
- Normal saves are neither loaded nor written. Reload starts a fresh experiment.

Files: domain/zero_c_network.gd, main_zero_c_core_fun.gd, main.gd,
tests/zero_c_*, tools/run_zero_c_core_fun.sh, playable-loop CI, charset/checker,
DEV_STATUS.json, this experiment note.

Acceptance: a mature tree stalls; disconnected fragments and ornamental loops
fail; at least two distinct meaningful repair networks pass; a good network
built in advance passes; route deletion invalidates current readiness; paused
or actively drawn frames cannot earn stability; normal/A/B regressions pass.

Tests: deterministic graph fixtures + current-main runtime integration, save
isolation, parser isolation, Japanese glyph coverage, Godot import/Web export.
Physical iPhone fun/readability/performance remains a user playtest, not CI proof.

Visual target: AXIVA Art Bible v1.0 and actual Drive North Star reopened in this
Work session. Warm miniature city, district hierarchy, roads/traffic readable.
Render growth on real occupied parcels; do not spawn decorative towers on roads.

Rollback: switch to normal/A/B mode or revert this experiment commit. No stored
city format is changed. Keep main and the deployed ZERO B baseline intact.

## Validation status

Implementation: complete as a separate experiment.
Automated validation: PASS; see AXIVA_ZERO_C_VALIDATION_2026-09-21.md.
Physical iPhone: NOT TESTED. Core Fun remains PARTIAL.
PRODUCTION_DECISION=UNDECIDED; RELEASE_APPROVAL=NOT_REQUESTED.


## Implemented prototype tuning and limits

- Stages use 6/14/24/40 accessible parcels; 40 is the large-city ceiling.
- A newly connected immature district may fill up to four functional parcels
  even at the ceiling, preventing a maturity dead end. Growth tops out at 72
  accessible parcels for this compressed experiment.
- Two-unit residual routing avoids falsely rejecting rings whose shortest path
  crosses a chord. Short shared terminal access is a fallback and still bears
  traffic load. Alternatives need spatial separation and a bounded detour.
- Trips are an aggregate approximation. The prototype does not simulate each
  resident's destination choices or prove production-scale traffic accuracy.
- True routes animate the existing bounded vehicle pool; queue markers and a
  contextual sentence identify the bottleneck. Final visual quality is untested.
- Metropolis scales actual occupied parcels around functional centers. There
  are no decorative C center towers placed on empty/road cells.
- City, backup and tutorial-state sentinels survive startup, play, reset's
  deletion hook and exit. ZERO C itself is intentionally ephemeral.
- Engine and Web export are tested locally, not a native iOS build.
- The exposed browser could not access the local build (ERR_BLOCKED_BY_CLIENT).
  No visual/device PASS is claimed.
