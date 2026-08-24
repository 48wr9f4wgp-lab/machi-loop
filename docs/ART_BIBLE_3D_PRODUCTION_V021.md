# MACHI LOOP 3D Art Bible — Production Asset Pass v0.21

Status: production target after Functional Build exit gate.

## Visual target
A bright, premium miniature city that reads instantly on a portrait phone. The target is denser and more authored than the v0.14 procedural prototype while preserving MACHI LOOP's readable road-first gameplay.

## Benchmark principles
- Pocket City 2: strong miniature-city readability and clean mobile-scale silhouettes.
- SimCity BuildIt: skyline hierarchy, district density, and recognizable building categories.
- TheoTown: information richness and the feeling that the city fills in continuously.

No single title is copied. MACHI LOOP keeps its own green/charcoal identity and automatic local-growth premise.

## Production hierarchy
1. Roads are the strongest dark graphic element.
2. Residential forms a low-rise warm perimeter with occasional apartment blocks after tier 3.
3. Commercial creates the cool mid/high-rise skyline around stronger road access.
4. Industry stays broad and low, with clear utility silhouettes.
5. Vegetation, parking, lamps, signs and civic decoration fill negative space without masking road topology.

## Palette
- Grass base: #6F9B63
- Grass light: #86B978
- Park lawn: #5F9B66
- Arterial asphalt: #252B2A
- Local asphalt: #4B5652
- Sidewalk: #C9CEC5
- Lane marking: #F0CF65
- Residential stucco: #F2EEE4 / #E9DCCB
- Residential roofs: #D87355 / #6BAA74 / #CC9B58
- Commercial glass: #73B6C9 / #CFE7EA / #4D839B
- Industrial body: #D5B688 / #9C7750
- UI accent: #71D0A2

## Building kit
### Residential
At least 8 visible silhouettes generated from modular parts:
- detached gable house
- split-level house
- townhouse
- narrow urban house
- courtyard home
- low apartment
- medium apartment (tier 3+)
- premium apartment (tier 4+)

### Commercial
At least 8 silhouettes:
- corner shop
- low retail block
- office slab
- stepped office
- glass tower
- podium tower
- twin-volume office
- high-rise crown tower (tier 4+)

### Industrial
At least 6 silhouettes:
- warehouse
- utility hall
- processing plant
- twin-stack plant
- logistics shed
- production hall with tanks/containers

## Roads and public realm
- Clean dark asphalt with curb/sidewalk separation.
- Crosswalks only where they improve intersection readability.
- Street lamps and parked cars capped to protect Web performance.
- Road markings should simplify topology, not create visual noise.

## Camera
Orthographic/isometric portrait framing. The camera follows the developed footprint, but keeps enough undeveloped land visible for the next road action.

## Performance budget for v0.21
- No per-window geometry explosion.
- Facades use a few broad window bands/panels.
- Decorative props are deterministically capped.
- Existing 3D fixture and Web export remain hard gates.
- MultiMesh remains a later optimization if device profiling requires it.

## Acceptance criteria
- A screenshot must read as a miniature city rather than a blockout.
- Residential/commercial/industrial categories must be distinguishable without UI labels.
- Tier 3+ must show a visible skyline step-up.
- Roads remain easier to read than building detail.
- iPhone Web workflow, save, FTUE and Functional Build regression remain green.
