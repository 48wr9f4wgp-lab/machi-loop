# AXIVA ZERO C2 — readable planning

Scope: title-local / WORKING HYPOTHESIS / 2026-09-21.
Baseline: deployed main 1722820f29d8ee23a9ee23c71d6122268a95c4ac;
local source 854e173 has the identical tree 1a30a5b.

Evidence: iPhone screenshot shows metropolis. Player reports drawing many roads
immediately and not understanding what mattered. This is NOT proof every dense
network wins, nor a Core Fun pass. Earlier response overstated that conclusion.

Goal: make road placement and its consequences legible under rapid input.
Existing: free roads, four same-function parcels qualify a center regardless of
fragmentation; feedback mostly appears at the final bottleneck/goal.
Change: mature centers need four accessible matching parcels with room in a
road-free 2x2 land block. Narrow strips still support small buildings. Local-road
automation must preserve that room. Road actions report actual new connections,
flow redistribution or lost developable space. Brief map marks link roads to
new buildings; intermediate stages announce themselves without stopping input.
Non-goals: economy, road quotas, forced congestion, input locks, longer timers,
new dashboard, art replacement, production balance, native release.
Files: C model/main/tests, charset, experiment/status notes.
Acceptance: dense one-cell strips cannot mature, selective road removal restores
room; two existing useful repair layouts and preventive planning still work;
no-op/failed edits do not invent success, rapid input keeps useful feedback;
normal save isolation and default/A/B regression remain green.
Tests: graph fixtures, real C transactions/growth, import/font and Web export.
Visual target: actual axiva_target.png reviewed, Art Bible v1.0. Restrained HUD,
city-led feedback. No visual PASS without rendered/device evidence.
Rollback: revert this C-only change; ephemeral C has no save migration.
New Pages build is not covered by the previous specific-build approval.

## Validation

- C graph: 23 PASS, including dense-road failure and land recovery.
- C runtime: 35 PASS, including real road erasure recovery, connection/route
  feedback, no-op handling, road-only eraser and save isolation.
- Default: 82 PASS; A: 25 PASS; B: 21 PASS. Total: 186.
- Godot 4.7.1 import and release Web export: PASS; no script diagnostics.
- Japanese subset: 184 required characters covered in the generated font.
- Both earlier alternate-route shapes remain valid. No forced prior failure.
- Product hypotheses, including the arbitrary 2x2 prototype footprint, require
  iPhone playtesting. Some dense but well-spaced grids should still succeed.
- Growth timings are unchanged: no added wait gate. Intermediate stage notices
  and new-building marks improve observability, not session-length guarantees.
- No claim of visual/performance improvement: the available browser previously
  reported missing WebGL2. Native iOS and full visual QA remain unverified.
- This supersedes the pre-upload delivery status in older C notes; PR #83 and
  deployed 1722820f are retained as the actual shared baseline.
