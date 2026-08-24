# MACHI LOOP — Functional Build Plan v1.0

Status: Execution plan
Date: 2026-08-24

## Objective
Finish the game systems before returning to full production-asset polish. The current 3D renderer proves the presentation direction; Functional Build now makes the city simulation strategically complete.

## Order of implementation

### FB-1 Demand System
Add explicit residential/commercial/industrial demand (0–100), expose it in state/UI, and drive autonomous growth selection with those pressures.

Acceptance:
- all three demand values change for understandable reasons;
- growth distribution reacts to demand;
- no demand state causes a hard progression lock;
- demand persists correctly through save/load if persistence is required by state design;
- automated tests cover obvious high/low-pressure scenarios.

### FB-2 Traffic Pressure & Recovery
Strengthen the link between network shape/capacity and growth/economy.

Acceptance:
- overloaded main roads visibly and numerically degrade city performance;
- widening/new redundancy can recover the city;
- no ordinary traffic state becomes unrecoverable;
- traffic explanation is legible without reading hidden formulas.

### FB-3 Economy & Operating Costs
Add recurring strategic costs for the systems that create value; remove infinite-growth economics.

Acceptance:
- cash flow can become weak/negative;
- the player always has at least one recovery option;
- growth pacing does not require artificial waiting;
- no early-game bankruptcy soft-lock.

### FB-4 High-Level City Services
Add a small set of city/district management levers: Mobility, Safety, Education, Green.

Acceptance:
- each service creates a distinct strategic benefit/tradeoff;
- services do not become repetitive building-placement chores;
- service state visibly changes one or more city metrics/growth patterns.

### FB-5 Progression Expansion
Extend city tiers, district unlock logic and long-term milestones.

Acceptance:
- at least six city tiers have materially different pressure/capability combinations;
- higher tiers introduce new decisions, not only larger numbers;
- the player always has a visible medium/long-term target.

### FB-6 FTUE Completion
Rebuild the first-session flow around the final Functional Build systems.

Acceptance:
- first road, first growth, first reward and first management decision are experienced naturally;
- no duplicated tutorial overlays;
- tutorial can be resumed/recovered after interruption;
- critical information is not delivered only through transient banners.

### FB-7 Functional Regression Gate
Before Production Asset Pass:
- new game works;
- existing save migration works;
- road draw/widen/remove works;
- city continues growing;
- demand/traffic/economy/services interact without deadlock;
- max currently supported progression remains reachable;
- Web/iPhone preview build remains usable.

## Architecture work required during Functional Build
The current version-layer scripts were useful for rapid vertical-slice iteration, but Functional Build must start reducing inheritance-stack debt.

Target boundaries:
- `domain/` — simulation rules and calculations;
- `state/` — serializable city state;
- `rendering/` — 3D scene representation;
- `ui/` — HUD, goals, management panels;
- `persistence/` — save/migration/recovery;
- `analytics/` — event adapter;
- `platform/` — Web/iOS/Android-specific adapters.

Rule: do not attempt a dangerous full rewrite. Extract one system at a time behind tests while keeping the current playable build working.

## Balance-data direction
Move tunable values out of scattered scripts into data/config where practical:
- construction prices;
- demand weights;
- road capacity;
- zone/job/population yields;
- policy modifiers;
- city-tier thresholds;
- service costs/effects;
- goal rewards.

## Exit criteria for Functional Build
Functional Build is complete when:
1. all core simulation systems above are implemented;
2. the player can progress from a fresh city through the planned v1.0 tier structure;
3. there is no major progression soft-lock;
4. save/migration/regression tests pass;
5. the game has enough strategic depth that Production Asset Pass will not need core simulation redesign.

Only then proceed to the full production 3D Asset Pass.
