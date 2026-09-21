# AXIVA v0.42: playable loop and recoverable input

Title: AXIVA / アクシヴァ
Scope: title-local
Date: 2026-09-21
Authority: implementation decision following the user's request to make the game enjoyable.
Base: main@27b0f0398db01d0a73650afc1fc44bc5f07bcca8
Status: implementation candidate; NOT physical-device verified.
ACTIVE_PHASE: VERTICAL_SLICE
PRODUCTION_DECISION: UNDECIDED
RELEASE_APPROVAL: NOT_REQUESTED

## Goal
Connect the existing first-road delight, structural problem, redevelopment and
recovery into a usable session. No giant map, rotation, districts, monetization,
Store work, broad content expansion or unlimited undo.

## Implementation decisions
- A single road quote is used by preview, confirmation and atomic mutation.
- Initial cash must cover the entire route. Goal rewards cannot fund an
  otherwise unaffordable purchase. No partially cleared buildings or payments.
- LOCAL parcels crossed by a strategic new arterial become ARTERIAL for the
  standard construction cost. No acquisition charge applies to LOCAL.
- R/C/I acquisition retains the working 20/32/28 supplement plus 12 construction.
  Values are not final balance. Existing arterial reuse is free.
- Occupied routes require one explicit in-game confirmation after the drag.
  Other editing, cancellation or adding a second finger cancels the pending plan.
  The simulation pauses during editing/confirmation so its quote cannot silently change.
- A commit result drives first seed, birth flags, effects, goal, FTUE, recovery,
  save and renderer. This is an explicit integration boundary, not a replacement
  of the entire historical simulation stack.
- The first road starts a bounded four-beat arrival wave: LOCAL, home, shop, home.
  All placements require eligible empty land beside an existing road. Later
  roads receive at most two demand-selected adjacent responses. Severe congestion
  suppresses these responses. Normal autonomous simulation remains active.
- Widening may qualify as recovery only after a meaningful measured congestion
  reduction. A bypass still requires a graph-cycle gain; demolition alone is not
  described as traffic redistribution.
- ROAD is previewed while dragging. WIDEN/REMOVE and HUD actions commit only on
  a completed single-finger tap. Multitouch, cancellation and focus loss cannot
  commit the pending edit. Touch-to-mouse emulation is disabled.
- Pan/pinch use actual screen-to-ground rays. Overview fits projected map bounds
  and does not reset city data. A close-up can center any unlocked cell.
- Acquisition targets, cost and confirm/cancel are visible. The in-game build is
  labelled v0.42. New Japanese text is checked against the generated font cmap.

## Acceptance tests
`tests/v42_main_play_loop_test.gd` loads current `main.gd` through a probe which
only selects ephemeral persistence. Input, road, growth, traffic and renderer
methods are not stubbed. It exercises first-road birth/reward, arrival/reveal,
occupied route quote/cancel/commit, LOCAL promotion, insufficient funds,
duplicate/locked quote handling, removal/widening multitouch arbitration,
canceled input, focus loss, projection/pan at two rendering sizes, and a natural
fresh-road -> pressure -> bypass -> recovery -> growth simulation run.
It is not a physical iPhone test and must not pass the Vertical Slice exit.

## Verification and delivery
Source is implemented; runtime/CI results must be recorded with the resulting
commit, not inferred from older layer fixtures. Run `bash tools/run_playable_loop.sh`
in the full repository. The wrapper isolates user:// in a temporary directory.
PR CI is separate from main push/deployment. Never interpret an empty PR-only
workflow query as a missing main deployment.

## Preserved work / rollback
Open PR #75 (`feat/v40-recoverable-roads` at 7ea548a...) is separate unmerged work.
Do not reset, close, overwrite or merge it as part of this candidate. In particular,
this patch does not introduce drag-to-bulldoze from that PR.
Normal save key and schema are unchanged. Roll back code to the base commit;
already purchased parcels remain legitimate roads in the existing save format.
User-side unsynced local work is unknown and must not be overwritten.

## Remaining gates
Physical iPhone: first-road delight, target comprehension, safe two-finger
navigation, edge editing, occupied bypass and visible recovery in one session.
Then lifecycle/save reload/thermal/frame-pacing/device validation. TARGET art
quality has not been reached merely by implementing these interactions.
