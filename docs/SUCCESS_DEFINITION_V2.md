# MACHI LOOP — Success Definition v2

Status: Proposed gate for Core Experience Rebuild / Vertical Slice v2
Date: 2026-09-16
Authority: GDD v2.0

## Product promise under test
**「一本の道から、街が生まれる。」**

Vertical Slice v2 exists to prove this promise before broader production continues.

## 1. Core Experience Success
A fresh player on a portrait iPhone-class screen must be able to:
1. understand that the first meaningful action is drawing a main road without reading a long tutorial;
2. draw the first road;
3. see an immediate, visually obvious autonomous growth chain;
4. understand that the growth happened because of that road;
5. encounter one structural urban problem created by the growing city;
6. identify a plausible intervention from city-visible evidence;
7. make the intervention and see a legible recovery/reconfiguration response.

Failure of any item above blocks production expansion.

## 2. Timing targets for the slice
These are initial validation targets and may be tuned only from observed playtest evidence.
- First meaningful input: <= 15 seconds from fresh-city control.
- First visible autonomous response after road commit: <= 2 seconds.
- First recognizable settlement: <= 15 seconds after valid first-road commit.
- First complete intervention → city reaction loop: <= 60 seconds.
- First meaningful structural problem: target 2–5 minutes.
- First problem → intervention → visible recovery loop: target <= 8 minutes total playtime.

The game must not require passive waiting to hit these targets.

## 3. Growth Delight Gate
The first-road sequence passes only if all are true:
- the city visibly changes from sparse/empty to inhabited;
- at least three distinct response channels are readable (for example local road branching, buildings, vehicles/people signal, construction/redevelopment, density change);
- growth occurs as a staged chain reaction rather than a silent instantaneous stat jump;
- road causality is spatially obvious;
- the 3D city remains the dominant visual surface during the payoff;
- sound/motion and supported haptics reinforce the payoff but are not required to understand it.

Automated tests can verify sequence/state, but the delight gate requires physical-device visual/feel review.

## 4. Causality Readability Gate
Without opening a permanent diagnostic dashboard, a player should be able to answer:
- Where is the city growing?
- What road/access change caused that growth?
- Where is the current problem?
- What visible evidence suggests the cause?
- Did my intervention improve or redirect the situation?

Contextual detail may explain the cause after the player notices the symptom. The UI must not require reading R/C/I, happiness, finance and traffic cards simultaneously.

## 5. Decision Density Gate
During active play after FTUE:
- meaningful planning opportunities should normally occur within tens of seconds, not minutes of idle observation;
- interventions must change spatial structure or growth trajectory, not merely toggle invisible modifiers;
- the slice must demonstrate at least two materially different valid responses to the structural problem where practical.

## 6. Recovery Gate
The slice must deliberately create one recoverable structural problem, initially **arterial congestion / insufficient network redundancy**.

Pass conditions:
- the problem is caused by simulated city structure, not a random debuff;
- congestion is visible in the world;
- growth/accessibility is measurably affected internally;
- a bypass/connector/widening response is available;
- after a valid intervention, traffic distribution and/or growth pattern visibly changes;
- no ordinary mistake creates an unrecoverable cash lock.

## 7. Smartphone Product Visual Gate
On the target portrait phone:
- the city/world is the visual hero and occupies the clear majority of useful gameplay space;
- routine gameplay does not show permanent demand + traffic + policy + finance + goal + settings panels together;
- persistent HUD is limited to essential city identity/stage, resource constraint, alerts/opportunities and current tool state;
- primary touch targets are comfortably usable and do not obscure the growth payoff;
- normal gameplay text is readable at default system scale;
- buildings, arterials, local roads, traffic concentration and problem location remain distinguishable without relying only on color;
- SFX/haptic toggles are not persistent gameplay HUD.

The previous dashboard-first iPhone presentation is explicitly not the target baseline.

## 8. Technical Gate
Before the slice can be called VERIFIED:
- Godot import/parse succeeds;
- existing save integrity/migration tests remain green or an explicit migration decision is documented;
- core simulation regression tests are updated for intentional behavior changes;
- Web export succeeds for iPhone test deployment;
- no new crash/progression blocker;
- no major performance regression on the physical target device;
- physical iPhone test validates touch, framing, readability and the complete first-road → problem → recovery loop.

CI success alone does not satisfy the physical-device gate.

## 9. Kill / Rework Criteria
Do not expand into district policies, transit, City Archive or broad content production if the slice cannot prove the core promise.

Trigger concept rework if repeated playtest evidence shows any of:
- autonomous growth feels passive rather than caused by the player;
- players cannot explain why development appeared or declined;
- road decisions feel cosmetic/equivalent;
- the structural problem is readable only through numbers/cards;
- the first-road payoff is not compelling even after focused game-feel iteration;
- making the city readable requires returning to dashboard-first UI.

## 10. Production Decision
Vertical Slice v2 passing these gates permits a **PRODUCTION_DECISION** for broader implementation. It is not RELEASE_APPROVAL and does not authorize App Store submission, public release, paid services or other external commitments.
