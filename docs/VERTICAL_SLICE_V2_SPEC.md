# MACHI LOOP — Vertical Slice v2 Spec

Status: Proposed implementation specification
Date: 2026-09-16
Depends on: GDD v2.0, SUCCESS_DEFINITION_V2

## 1. Slice question
Can MACHI LOOP make the player feel that one road caused a living city to emerge, then turn that growth into a readable strategic problem and satisfying recovery?

Everything in this slice serves that question.

## 2. Scope
### In
- one compact open-plain test map;
- fresh-city FTUE;
- main-road drawing;
- autonomous local-road generation;
- rapid residential-led settlement growth;
- visible vehicle movement;
- accessibility-driven commercial response;
- one congestion/network-redundancy phenomenon;
- widening and/or bypass/connector recovery action;
- city-dominant portrait HUD rebuild;
- contextual problem explanation;
- existing feedback/save foundations where compatible;
- deterministic automated fixture for the full slice sequence.

### Out
- full district-direction system;
- full public transport;
- expanded policy inventory;
- City Completion balancing;
- City History/time-lapse production system;
- CITY ARCHIVE production system;
- multiple terrain families;
- store/release work;
- broad content expansion.

These remain post-slice work and are blocked until the core experience passes.

## 3. Golden-path flow
### Beat 0 — Empty land
Camera frames mostly empty terrain with one obvious external connection/entry edge. UI is minimal. Primary prompt: **「最初の道を引こう」**.

### Beat 1 — First road
Player drags from the valid connection into buildable land. Preview is clear; commit gives immediate feedback.

### Beat 2 — The city is born
Within the success timing budget:
1. first movement/arrival signal;
2. first residential construction;
3. additional homes;
4. automatic local-road branch;
5. population visibly increases through world growth rather than a large stat animation;
6. small commercial response appears at a plausible accessible location.

Camera may subtly reframe to reveal the settlement. Message: **「街が生まれました」**.

### Beat 3 — Self-reinforcing growth
The settlement continues to grow because accessibility, residents, jobs/spending and connected land reinforce one another. Growth must slow naturally before it becomes a passive screensaver.

Player receives another useful road-planning opportunity rather than waiting.

### Beat 4 — Structural pressure
The initial arterial becomes overloaded because too much movement depends on one corridor. World signals:
- visibly denser/slow traffic;
- growth/redevelopment pressure around the corridor;
- contextual alert such as **「この道に交通が集中しています」**.

No permanent traffic card is required.

### Beat 5 — Player diagnosis
Selecting/tapping the affected corridor may reveal a compact contextual explanation: this corridor carries most access to the settlement. Show a likely class of remedy without prescribing one exact line.

### Beat 6 — Intervention
Player can improve the structure using at least one implemented high-leverage action:
- create a bypass/parallel connector; and/or
- widen the overloaded arterial.

Bypass/connector is preferred as the stronger demonstration because it can visibly redistribute movement and alter future growth.

### Beat 7 — Recovery payoff
After intervention:
- some traffic visibly redistributes or speeds up;
- accessibility improves internally;
- stalled growth resumes or redirects;
- development may begin around the new route/node;
- feedback makes the causal result obvious.

Target reaction from player: **「道一本で街の流れが変わった」**.

## 4. Simulation rules required for slice
### Accessibility
Every developable cell/parcel receives a simplified accessibility score based on connection to the external entry and travel burden/capacity through the road graph.

### Latent demand
The map begins with latent settlement potential. It does not convert to development until road access makes land viable.

### Residential growth
Accessible land near a valid road is the first growth consumer. Residential construction adds residents and trip generation.

### Commercial response
Resident/spending potential plus accessibility creates commercial pressure. Commercial development should prefer stronger access/intersection locations so a center begins to form naturally.

### Local roads
Local roads are simulation-owned. They branch only where they improve access to viable development and must remain visually subordinate to player arterials.

### Congestion
Trips consume road capacity. A single-access city should naturally overload its arterial at the scripted/fixture scale. Congestion reduces effective accessibility/growth enough to be noticed but not enough to deadlock the city.

### Recovery
New network redundancy changes path distribution and effective accessibility. The simulation must produce a visible post-intervention difference; do not fake the recovery only with a success banner.

## 5. Presentation architecture
### Persistent
- compact city identity/stage;
- compact cash/resource display;
- contextual alert/opportunity affordance;
- bottom primary tool control(s).

### Contextual only
- traffic detail;
- growth cause;
- district/parcel diagnostics;
- finance breakdown;
- future policy/service detail.

### Settings
SFX/haptic controls move out of the gameplay HUD.

## 6. Growth choreography
Simulation remains authoritative, but presentation can stage valid results for readability:
- construction anticipation;
- building rise/pop animation;
- small dust/particle cue;
- local-road draw-in;
- vehicle arrival;
- milestone audio/haptic;
- short camera ease/reframe.

Do not block input for a long cinematic. The player should regain/retain control quickly.

## 7. Deterministic test fixture
Create a fixture with a known map and road sequence:
1. fresh state;
2. commit first arterial;
3. assert first eligible growth response;
4. advance deterministic simulation ticks;
5. assert residential + local-road + commercial response;
6. advance until congestion threshold;
7. assert congestion phenomenon and reduced effective accessibility;
8. add known bypass/connector;
9. advance ticks;
10. assert traffic redistribution/accessibility recovery and renewed/redirected growth.

This fixture validates mechanics, not visual delight.

## 8. Reuse audit
Before implementation, classify current systems:
- **KEEP**: road graph/drawing where compatible, save safety, feedback infrastructure, analytics/observability foundation, export/CI infrastructure.
- **ADAPT**: auto-growth, traffic, economy, progression, renderer/camera.
- **HIDE/REPLACE PRESENTATION**: permanent R/C/I, traffic, policy, deficit, large goal and SFX/haptic HUD panels.
- **DEFER**: broad services/policies until the slice passes.

Do not delete working foundations merely because their current presentation is rejected.

## 9. Implementation order
1. Freeze old dashboard-first UI as legacy reference; do not polish it.
2. Add deterministic slice map/fixture.
3. Implement/rebalance accessibility + latent-demand first-road growth.
4. Make local-road/building/vehicle chain visually legible.
5. Implement congestion phenomenon from the same simulation.
6. Implement bypass/connector recovery and verify causal state change.
7. Rebuild portrait HUD around city-as-UI.
8. Add growth/recovery game-feel choreography.
9. Automated regression + Web export.
10. Physical iPhone audit against SUCCESS_DEFINITION_V2.

## 10. Exit condition
The slice is complete only when automated gates are green **and** a physical iPhone run demonstrates the full sequence:

**empty land → first road → city born → visible growth → structural congestion → player intervention → visible recovery/reconfiguration.**

Passing the slice supports the next PRODUCTION_DECISION. It does not constitute RELEASE_APPROVAL.
