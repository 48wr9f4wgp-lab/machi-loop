# AXIVA — GDD v2.0

Status: Proposed canonical game-specific GDD after concept relock
Official title: AXIVA（アクシヴァ）
Legacy title alias: MACHI LOOP
Date: 2026-09-16
Supersedes on merge: GDD v1.0

## 1. Product thesis
AXIVA is a portrait 3D city-growth simulation about causing a living city to emerge from a small number of high-leverage planning decisions.

**Player-facing promise:**
> 一本の道から、街が生まれる。

The player does not manually place routine buildings or local streets. The player creates the conditions for growth; the city responds autonomously, develops its own structure, creates new pressures, and records a unique urban history.

The primary emotional target is not spreadsheet optimization. It is the visual satisfaction of watching an empty landscape rapidly become a city because of the player's intervention.

## 2. Design pillars
1. **Explosive visible growth** — the first road must trigger an immediate, legible chain reaction.
2. **City as the UI** — normal play is read primarily from the 3D city, traffic, construction, density and district condition; detailed numbers are secondary diagnostics.
3. **Indirect control** — the player guides development rather than placing ordinary buildings one by one.
4. **Emergent urban problems** — problems come from the city's structure and history, not arbitrary punishment.
5. **Escalating authority** — the player begins with roads and gains higher-level planning tools only as the city becomes complex enough to justify them.
6. **A city has a story** — a completed city preserves its growth history and remains visitable.

## 3. Core Loop
1. Observe the city and its visible pressure.
2. Make one high-leverage intervention.
3. Watch an immediate growth/reconfiguration response.
4. Let population, jobs, accessibility, land value and movement reshape the city.
5. A new structural opportunity or problem emerges.
6. Read the cause from the city itself.
7. Intervene again with roads, district direction, transit or a high-level policy.
8. Repeat until the city reaches a completion state.

**Core emotional loop:**
Intervention → chain reaction → surprise/satisfaction → consequence → understanding → next intervention.

Waiting without a meaningful decision is not gameplay.

## 4. Meta Loop
1. Start from a mostly empty map.
2. Create the first growth axis.
3. Grow from settlement to metropolis.
4. Reach City Completion.
5. Review the city's timeline and defining turning points.
6. Preserve the city in CITY ARCHIVE and allow continued sandbox play.
7. Unlock/start a new terrain condition and create a different city.

## 5. Player verbs and authority progression
### Stage 1 — Settlement: create growth
- Draw strategic main roads.
- Remove/re-route a main road when necessary.

No policy wall, service dashboard or dense statistics at first contact.

### Stage 2 — Town: shape growth
- Draw main roads.
- Widen overloaded main roads.
- Create redundancy/bypasses/connectors.

### Stage 3 — Small city: direct districts
Unlock a small set of district-level directions, such as:
- residential encouragement;
- commercial encouragement;
- densification;
- greening/quality emphasis.

These are influences, not manual zoning of every parcel.

### Stage 4 — City: create mobility axes
Unlock high-level public transport. The preferred interaction is corridor/axis designation and strategic network decisions rather than repetitive stop-by-stop micromanagement.

Transit must visibly change accessibility and development patterns.

### Stage 5 — Major city / metropolis: govern at high level
Unlock a small number of consequential city policies. Policies must visibly alter city evolution and create trade-offs. Do not recreate a desktop city simulator's administration surface.

**Permanent rule:** routine buildings and local roads remain simulation-driven throughout the game.

## 6. Autonomous growth model
The simulation should create understandable causal chains.

### Foundational causal chain
Main-road access
→ buildable accessible land
→ housing/employment development
→ population/jobs
→ spending and movement
→ commercial/industrial response
→ traffic and accessibility changes
→ land-value/density changes
→ redevelopment
→ new urban structure.

### Internal simulation state
The implementation may use detailed values including:
- population;
- jobs;
- household/worker balance;
- accessibility;
- road capacity and congestion;
- residential/commercial/industrial pressure;
- land value;
- density;
- district attractiveness;
- cash/economic sustainability;
- policy/transit modifiers.

These values are simulation inputs and diagnostics. They are not automatically entitled to permanent HUD space.

### Growth rule
Development requires plausible access and pressure. New development should preferentially reinforce understandable urban patterns: road frontage, intersections, accessibility nodes, established centers and later transit corridors.

The player should be able to look at a city and form a useful hypothesis about why an area is growing or declining.

## 7. Emergent urban phenomena
Player-facing problems are consequences of city structure. Candidate phenomena include:
- chronic congestion caused by insufficient network redundancy;
- housing shortage caused by poor access to viable residential land;
- employment imbalance;
- declining old center after traffic/access shifts elsewhere;
- rapid densification around a strong accessibility node;
- low-density sprawl caused by excessive outward road expansion;
- overloaded growth corridor;
- split city caused by weak cross-connections;
- new subcenter formation after a bypass/transit intervention.

Do not surface these primarily as random debuffs. The phenomenon should be visible in the city before or alongside any explanatory UI.

Negative states must remain recoverable. A weak decision should create an interesting repair problem, not an unrecoverable dead city.

## 8. Challenge model
AXIVA has no ordinary fail screen. Difficulty comes from the fact that successful growth creates new complexity.

The player should repeatedly experience:
> "The city grew because of what I did; now that growth created a new problem I need to understand."

A healthy challenge has:
- a visible symptom;
- a traceable structural cause;
- at least one practical intervention;
- a visible response after intervention.

Cash can constrain choices but must never produce a state where the player has no meaningful recovery action.

## 9. Progression
Progression represents a change in urban form and player responsibility, not only a number threshold.

Provisional stages:
1. 集落 — first road, first homes, first local growth.
2. 町 — recognizable neighborhoods and first traffic pressure.
3. 小都市 — multiple districts and district direction.
4. 都市 — competing centers and public-transport decisions.
5. 大都市 — high density, network restructuring and major trade-offs.
6. メトロポリス — complex multi-center city and completion challenge.

Each transition requires:
- a visible transformation in city form;
- at least one new planning capability;
- at least one new class of structural pressure.

## 10. City Completion
A city can reach a formal completion state when it demonstrates sustained metropolitan maturity rather than merely crossing one population number.

Final thresholds must be tuned in playtest, but completion should combine a small set of legible criteria such as:
- sufficient scale/population;
- functioning employment/housing balance;
- acceptable city-wide accessibility;
- recovery from or management of major structural pressures;
- required metropolis progression milestones.

Completion is a milestone, not forced retirement. The city remains playable afterward.

## 11. City History and CITY ARCHIVE
The game records meaningful snapshots/events from first road to completion.

Candidate history markers:
- first main road;
- first residential cluster;
- first commercial center;
- first major congestion crisis;
- first bypass/transit axis;
- formation of a second urban center;
- major density transition;
- population milestones;
- City Completion.

At completion, present a concise visual timeline/time-lapse showing how the city transformed.

CITY ARCHIVE stores completed cities with summary identity, terrain, completion time/era, population/scale and notable urban form. Completed cities can be revisited and continued in sandbox play.

The archive is the primary meta-progression collection, not an excuse for stat inflation.

## 12. Terrain replayability
New cities should change planning constraints through terrain rather than merely raising numerical difficulty.

Candidate map families:
- open plain;
- coast;
- river/bridge city;
- mountain/valley;
- island/limited land.

Terrain must materially change viable road structure and resulting urban form.

## 13. FTUE / first 60 seconds
The first minute must prove the product promise.

Target sequence:
1. Mostly empty 3D landscape with one clear connection/entry point.
2. One dominant instruction: **「最初の道を引こう」**.
3. Player draws a main road.
4. Road commit receives immediate sound/motion/haptic acknowledgement where supported.
5. A first vehicle/settler signal appears.
6. First homes emerge quickly.
7. Local streets branch automatically.
8. Additional development follows in a readable chain reaction.
9. Camera framing reveals that a settlement has formed.
10. Message: **「街が生まれました」**.
11. The next opportunity is communicated through the city, not a dashboard dump.

Target emotional outcome: "I drew one road and all of this happened."

## 14. UI/UX doctrine
The 3D city is the dominant visual surface.

### Persistent HUD
Keep only information required for moment-to-moment decisions, provisionally:
- city stage/identity;
- cash/resource constraint;
- minimal alert/opportunity indicators;
- current primary tool state.

### Contextual UI
Demand, traffic causes, district condition, finance detail, policy detail and diagnostics appear contextually or on demand.

### Prohibited direction
Do not return to a screen dominated by permanent cards for demand, traffic, policy, finance, goals and settings simultaneously.

Audio/haptic toggles belong in settings, not the primary play surface.

Critical information cannot rely on color, sound or haptics alone.

## 15. Visual and game-feel direction
- Stylized 3D miniature city with strong portrait-phone readability.
- Empty-to-dense transformation must be dramatic.
- Construction, redevelopment and traffic flow are reward surfaces, not background decoration.
- Arterials, local streets, district centers and density hierarchy must be readable without opening diagnostics.
- Growth should use staged motion/VFX/audio so that chain reactions feel authored while remaining simulation-driven.
- Camera behavior should help reveal transformation without taking control away from the player.

## 16. Economy and services
Economy exists to create trade-offs, not bookkeeping work.

The player should understand whether the city can afford a major intervention without constantly reading an accounting panel.

Services are high-level influences. Avoid utility-network micromanagement and repetitive one-building-per-block placement. Existing Mobility/Safety/Education/Green concepts may survive only where they reinforce autonomous city evolution and create visible strategic differences; otherwise simplify or remove them.

## 17. Policies
Policies are late/mid-game high-leverage choices. Keep the inventory small.

A policy is valid only if:
- it creates a meaningful trade-off;
- it visibly changes city evolution;
- the player can understand its consequence from the city;
- it does not require permanent dashboard attention.

Existing policy implementations are subject to revalidation against these rules.

## 18. Save and history requirements
The city is persistent. Existing save-safety requirements remain mandatory:
- schema_version;
- checksum/integrity;
- atomic write;
- backup;
- corruption recovery;
- migration fixture tests.

The new city-history/archive system must be versioned and migration-safe. Do not break existing saves silently; if a gameplay migration cannot preserve semantics, define an explicit compatibility strategy before implementation.

## 19. Analytics success model
Before public launch, instrumentation must answer whether the new promise works.

Key event families:
- app/session start/end;
- FTUE step and completion;
- first-road draw/commit/cancel;
- time from first road to first building/local road/settlement;
- road draw/widen/remove;
- district-direction/transit/policy decisions after unlock;
- urban-phenomenon entry and recovery;
- city-stage transition;
- City Completion;
- archive/revisit/new-city start;
- save/load/recovery result;
- performance/crash metadata without unnecessary PII.

Exact KPI targets belong in Success Definition, not in the GDD.

## 20. Non-goals
- manual placement of routine residential/commercial/industrial buildings;
- manual local-road micromanagement;
- manual utility networks;
- desktop-scale traffic engineering controls;
- large permanent management dashboards;
- arbitrary random punishment as the main challenge source;
- mandatory backend/account;
- multiplayer/social alliance systems;
- forced ads/gacha/energy;
- large daily LiveOps calendar.

## 21. Feature acceptance rule
A feature must materially improve at least one of:
- the satisfaction/clarity of autonomous city growth;
- the meaning of high-leverage planning decisions;
- the legibility and recovery of emergent urban problems;
- the transformation from settlement to metropolis;
- City History / Archive / replay motivation;
- product quality, accessibility, performance or reliability.

If it mainly adds management surface area without strengthening those outcomes, reject it as scope creep.

## 22. Current implementation status after concept relock
The existing Functional Build is an implementation asset, not the new design authority.

Reusable foundations include road drawing, auto-growth infrastructure, traffic/economy/service/progression systems, save safety, feedback, analytics/observability foundations and Web/iPhone test deployment.

However, existing HUD hierarchy, exposed demand/finance presentation, progression presentation, service/policy prominence and growth pacing must be audited against GDD v2.0 before reuse.

Do not polish the current UI as-is. The next production phase is a **Core Experience Rebuild / Vertical Slice v2** proving:
1. first-road → explosive autonomous growth;
2. city-readable cause/effect;
3. one emergent structural problem;
4. one satisfying intervention/recovery;
5. portrait-phone visual hierarchy with the city as the primary surface.
