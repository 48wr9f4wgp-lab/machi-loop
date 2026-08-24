# MACHI LOOP — Visual / Game Feel Benchmark Lock

Date: 2026-08-24
Scope: Mobile portrait vertical slice v0.4

## Benchmark roles

### Pocket City 2
Role: mobile city-builder readability and low-friction depth.
Transferable principle: the player should see the city react quickly to a decision and should not need long waits before the next meaningful action.
Do not copy: specific UI, 3D assets, layouts, copy, or branded presentation.

### TheoTown
Role: dense city-state readability and long-run simulation depth.
Transferable principle: even when the simulation is deeper than the screen can explain, roads, zones, growth, and problem states must remain visually distinguishable.
MACHI LOOP divergence: do not require detailed local-road micromanagement; only main roads are player-authored.

### SimCity BuildIt
Role: mass-market clarity, strong status hierarchy, obvious progression.
Transferable principle: population, cash, city level, and problems must be readable within a glance.
MACHI LOOP divergence: avoid waiting-heavy chores and monetization-shaped friction in the core loop.

### Bit City
Role: continuous growth, ambient city motion, short-session satisfaction.
Transferable principle: something should almost always be moving, earning, appearing, or improving so the city feels alive even when the player is not tapping.

## v0.4 changes derived from the benchmark

1. Main-road cells render as connected road segments instead of isolated dark squares.
2. Placing the first main road seeds the first residential growth immediately.
3. Local roads and buildings receive short spawn pulses and floating feedback.
4. Moving traffic markers make established roads feel active.
5. Road-drag preview shows the live construction cost.
6. City-level progress receives a visible population-to-next-area bar.
7. Cash collection receives a short HUD flash.
8. Building silhouettes become more legible by use type without copying another title's assets.

## Success check for this pass

- First road placement produces a visible city response immediately.
- Player can distinguish main road / local road / residential / commercial / industrial at phone size.
- The board looks alive without adding manual micro-management.
- Core controls remain large enough for one-handed portrait play.
- Runtime and Web export gates remain green.
