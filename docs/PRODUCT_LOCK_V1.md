# MACHI LOOP — Product Lock v1.0

Status: Locked for Functional Build
Date: 2026-08-24
Authority: game-specific specification; overrides generic project rules where applicable.

## Product statement
MACHI LOOP is a portrait mobile 3D city-management simulation where the player designs only the main roads and the city automatically generates local streets, buildings and growth around that structure.

The product promise is: **keep the strategic pleasure of city planning while removing the repetitive micromanagement of drawing every local street and placing every basic building.**

## Context Lock
- Product name: MACHI LOOP
- Primary platforms: iOS / Android
- Development preview: Web/PWA on GitHub Pages; preview technology is not the final distribution commitment.
- Launch region: Japan first; English-ready from architecture/localization day one.
- Audience: casual-to-midcore city-builder players who like planning and optimization but do not want Cities: Skylines-level road and utility micromanagement on mobile.
- Genre: 3D city-management simulation / streamlined city builder.
- Orientation: portrait.
- Input: touch-first, one-hand viable; drag for main-road drawing, tap for management actions.
- Session target: 3–10 minute normal sessions, with optional longer 20–40 minute city-planning sessions.
- Player mode: single-player.
- Connectivity: offline-first.
- Backend requirement for v1.0: none required for core play.
- Save model: local-first, schema-versioned, atomic save with checksum and backup recovery. Cloud sync is not required for v1.0 unless later added as a platform feature.
- Privacy class: low; no account required for v1.0. Analytics, if enabled, must avoid direct PII.
- Visual target: polished stylized 3D miniature-city diorama; high readability on portrait mobile; not photorealistic.
- Device tier target: modern mid-range mobile devices. Performance target is 60 FPS where practical, with a hard gameplay floor of 30 FPS on minimum supported devices; final minimum-device list is set during Performance Gate after profiling.
- Production scale: small-team / AI-assisted production, deliberately avoiding content systems that require large live teams.

## Core Loop
1. Read the current city problem and demand.
2. Draw or improve a main road.
3. The city automatically generates local roads and buildings around the network.
4. Population, jobs, cash, traffic and happiness react.
5. New constraints appear: housing pressure, job pressure, congestion, service pressure or finance pressure.
6. The player responds with roads, widening, policy and high-level city services.
7. Districts and city tiers unlock.
8. Repeat at a larger scale with new city problems.

## Meta Loop
- Expand from a small district into a large city.
- Unlock higher city tiers, district types, policies, service systems, road capabilities and visual density.
- Develop a recognizable city shape over multiple sessions.
- Complete short city goals while pursuing long-term metropolitan milestones.

## Design Pillars
1. **Main roads are the player’s primary verb.** Local road/building growth is automated.
2. **The city visibly reacts.** Every meaningful road/management decision must create understandable visual and numerical feedback.
3. **Problems create decisions, not chores.** City pressure should ask for strategic responses, not repetitive maintenance clicks.
4. **Growth must remain legible.** A denser city cannot become visually unreadable on a phone.
5. **Recovery is mandatory.** Bad traffic or finance states must remain recoverable; accidental soft-locks are defects.
6. **No fake waiting as gameplay.** Timers may support pacing, but the player must always retain a meaningful action.

## Scope Guardrails
### In v1.0
- Main-road drawing and widening.
- Automatic local-road and building growth.
- Residential / commercial / industrial demand.
- Population, jobs, cash, happiness and traffic systems.
- City policies.
- High-level city services that affect city-wide or district-wide metrics.
- District and city-tier progression.
- Short goals and long-term milestones.
- Save/recovery.
- Japanese UI and localization-ready string architecture.
- Production-quality 3D assets, audio, haptics, VFX, analytics and performance QA.

### Explicitly not in v1.0 unless later promoted
- Manual placement of every house/shop/factory.
- Manual drawing of every local street.
- Manual water pipe, power line or sewer-network routing.
- Multiplayer, alliances, PvP or competitive leaderboards.
- User accounts as a requirement for play.
- Large-scale LiveOps calendar.
- Gacha.
- Forced advertising.
- Photorealistic rendering.
- Pedestrian-level simulation comparable to desktop hardcore city simulators.

## Monetization Lock
- v1.0 direction: **premium single-purchase product** on mobile.
- No forced ads, no gacha, no energy system.
- Optional paid expansion/DLC is allowed after v1.0 if the base product is successful.
- Exact price is not locked yet and must be set using current store/competitor research before Release Candidate.

Rationale: premium monetization fits an offline-first, low-LiveOps city builder and avoids designing the simulation around artificial timers or ad inventory.

## LiveOps Lock
- v1.0 does not depend on LiveOps for retention.
- Retention must come from city progression, goals, unlocks and emergent city problems.
- Small optional content updates are allowed post-launch, but no daily-event treadmill is required for product viability.

## Technical Lock
- Engine: Godot remains the production engine unless profiling proves a hard blocker.
- Game/domain state must remain separable from rendering.
- Web/PWA remains the rapid iPhone test surface during development.
- Final native packaging/distribution must be validated before RC; Web preview success alone is not sufficient evidence for Store readiness.

## Change Control
Changes to the following require an explicit new game-specific decision record because they materially alter the product:
- player manually drawing local streets;
- switching to free-to-play/ad-driven monetization;
- landscape-only orientation;
- online-only core play;
- multiplayer as a core requirement;
- abandoning automatic city growth;
- full engine migration.
