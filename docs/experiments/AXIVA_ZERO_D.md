# AXIVA ZERO D — room to expand

Title-local experimental record, proposed 2026-09-22 JST; trial verdict 2026-09-24.
Baseline: deployed C2 a425f2b277451a1e479fa85ba4929fb59be6ae44;
local 5e76e4f has the identical full tree 5dc7e39c.

Evidence: user reports connecting roads and feeling finished, even while C2
shows city rather than metropolis. User proposes the map is too small and
authorizes a roughly four-times-area expansion with readable scale and pan.

Goal: ask whether choosing the next district to develop creates continued play.
Change: separate `?zero=d` / native `-- --zero-d` experiment, 32x44 (1408 cells,
4x 16x22). Six regions give residential, commercial and industrial growth two
locations each. Root-connected roads open autonomous frontage growth; drawing
toward another region changes the building mix. All land is available from the
start, no added gates. D does not inherit C2's maturity/stall/win conditions.
Start with a small populated settlement. Keep local camera scale; add explicit
one-finger move tool, existing two-finger pan/pinch, overview and return-to-town.
Overview region labels can focus a district without drawing roads.
Non-goals: infinite world, new economic constraints, forced congestion, new
metropolis threshold, native release, replacing A/B/C, full art overhaul.
Prototype limit: 32 buildings per region, up to 192; no claim of production
balance. Region growth/frontage and connections are real state, not decorations.

Files: base grid dimensions become per-instance defaults (16x22 unchanged),
D model/main/probe/tests/runner, main routing, charset/checker, playable CI,
status/experiment notes. D sets dimensions before initialization/rendering.
Normal saves stay 16x22; D does not load/write/delete normal city/FTUE saves.
Target: Art Bible v1.0 and actual axiva_target.png reviewed in this chat.
Rollback: route back to C2 / revert D; ephemeral experiment has no save migration.

Acceptance: 4x world; all corners navigable, pan/pinch/focus create no roads;
return-to-town restores readable scale; commercial/industrial routes produce
different growth beyond old bounds; first destinations do not end growth;
isolated roads do not grow; no forced road-count/space/time gate; persistence
sentinels and default/A/B/C regression pass. Validate import/font/Web export,
touch event and projection tests; device readability/performance/fun stay open.
The user approved this exact D build for merge and Pages on 2026-09-21.

## Validation evidence

- Godot 4.7.1: import/parse PASS; Web export validation recorded in PR.
- D runtime: 83 checks PASS. Actual InputEventScreenTouch/Drag road drawing,
  pan/pinch arbitration, overview focus, return, old-boundary crossing, isolated
  roads, root removal/recovery and normal-save/FTUE sentinels are covered.
- 430x932 and compact 375x812 geometry checked. All six overview labels are
  visible and non-overlapping; tool targets are at least 44x44. A compact-screen
  overlap was found and fixed with bounded screen-space label placement.
- Reversed station-road gesture yields the same commercial growth focus; focus
  is derived from newly reachable frontage, not the last pointer coordinate.
- Observed connected buildings: 94; region counts [22,19,32,0,21,0]. The station,
  logistics and outer industrial areas grow through genuine road transactions.
- Original local camera size: 30.56; overview is wider, focus restores scale.
- Default 82, A 25, B 21, C graph 23 + runtime 35 checks PASS. Total with D: 269.
- Actual generated Japanese font covers all 194 required characters.
- No C2 gate or save migration is applied to D. All regions can be developed in
  any order; isolated roads need connection to the initial settlement.

## Limits / next decision

This tests spatial expansion and land-use feedback. D deliberately does not
simulate a new demand/traffic challenge or prove a repeating strategic loop.
Vehicle rendering remains the inherited approximation. Six fixed land-use
regions and a 192-building limit bound the prototype; this is not an infinite
city or production balance. The 3 starting homes and short road are visible
starting state, not a player success event.

The available browser previously lacked WebGL2. Geometry and headless behavior
checks are NOT a screenshot/visual pass. iPhone frame time, touch feel, memory,
legibility of shifted labels and desire to expand remain unverified. Target
image reviewed earlier in this chat, not recreated. No market/Greenlight pass.

## Deployment and user-trial verdict

- PR #85 merged as `68bc91bfdaaa803f412ba6b473014f4b35ad5cf8` on
  2026-09-21. Four main workflows passed; live `build.txt` matched the merge.
  The downloaded live PCK booted headlessly. This does not prove native iOS
  performance, visual quality or touch feel.
- In response to the specific, explanation-free question of whether they wanted
  to choose a further district after connecting nearby destinations, the user
  answered 「ならない」 on 2026-09-24. Record D's **expansion-desire hypothesis as
  not supported by this trial**. Do not reinterpret this as a test of all city
  gameplay, all players, or map size in isolation.
- The 4x map, six destination types and autonomous building growth establish
  room and mechanical response, but have not produced a reason to make the next
  road choice. The same verb can still feel finished after connecting targets.
- Stop adding map area, fixed destinations, gates or art solely to rescue D.
  Return to the title's proposed core sequence: growth creates a legible
  structural problem; a road choice changes the traffic/growth pattern; the
  player recognizes a satisfying recovery. Test at least two materially
  different viable road responses where practical, without prescribing a line
  or faking a debuff. Reuse existing recovery mechanics before expanding scope.
- Next decision gate: on iPhone, after the first visible problem, does the
  player identify a plausible action and *want* to try another road solution?
  Capture the action, visible consequence and spontaneous reaction. Automated
  simulation checks can establish causality but cannot establish desire.

Status: Vertical Slice remains open; Core Fun has not passed; production is
UNDECIDED. This verdict does not authorize a new Pages build or native release.
