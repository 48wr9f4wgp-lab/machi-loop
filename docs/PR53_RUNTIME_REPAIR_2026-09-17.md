# PR #53 runtime repair evidence

Scope: MACHI LOOP / title-local engineering evidence, 2026-09-17.
Phase: VERTICAL_SLICE. PRODUCTION_DECISION: UNDECIDED.
RELEASE_APPROVAL: NOT_REQUESTED.

## Root cause and minimal gameplay fix

The original PR head `870b0b5ba4df12594365b8455219c19231d3d0ba`
references undeclared `mode` at `main_v23_core_experience.gd:82`.
The inherited tool selection variable is `current_tool` in `main_mobile.gd`.
Godot 4.7.1 (`a13da4feb`) direct script checking reproduces:
`Identifier "mode" not declared in the current scope.`
The entry scene only reports `Could not resolve class`, obscuring this cause.

Commit `46afb9e2033694d6b960ecfbb667326e0555cc7d` changes that one reference.
Local editor import and runtime smoke pass without script errors afterward.

## Regression-gate correction

A log-aware local run of 25 existing fixtures found three failures despite
zero process exit codes. All three also reproduce on the handed-off main
baseline `54d5a38784483d7ee21e371a5faa02783a575820`:

- Functional regression and road-only bulldoze fixtures call feedback methods
  without initializing their controller. Fixtures now initialize a real
  controller through SceneTree before invoking gameplay methods.
- Functional regression expects cash below 700 after a six-cell road, but the
  existing 80 goal reward exceeds its 72 construction cost. The assertion now
  checks the exact cost and earned reward balance.
- Legacy migration expects schema 5 although the active writer uses schema 6.
  The existing state-preservation assertions remain; the output schema is 6.

Two fixture helpers previously called `quit(1)` and subsequently overwrote it
with `quit(0)`. They now retain failure counts and report a failing final exit.
The build, feedback and road-only workflows use `tools/run_godot_fixture.py`
to reject script errors and assertion-failure diagnostics even with zero exit.
A deliberately failing zero-exit fixture was verified to be rejected.

GitHub run `35165910767` reports success but contains the same old fixture
errors in its log. Its green status alone is insufficient evidence; the next
commit must pass the corrected gates before merge.

## Limits and next task

This restores runtime loading and trustworthy regression checks; it does not
complete Vertical Slice v2 or approve gameplay presentation.
Known next work includes a deterministic first-road/growth/congestion/recovery
fixture, simulation-driven route redistribution, replacing the dashboard
overlay, matching tool hitboxes to displayed controls, removing hidden settings
hitboxes, and physical iPhone validation. The birth flag also needs evaluation
against synchronous first-road growth and existing loaded saves.

Local fixture shutdowns still emit some pre-existing ObjectDB leak warnings;
no claim of leak-free runtime, physical-device performance or visual quality.
No save schema or runtime save behavior is changed by this repair.
Recovery: retain the PR branch and previous main; reverse only these commits
if needed, without rewriting history or removing player data.
