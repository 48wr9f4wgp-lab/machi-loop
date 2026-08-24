# ADR — MACHI LOOP v0.10 3D Vertical Slice

Status: Accepted for vertical slice

## Context
MACHI LOOP already has a functioning Godot simulation, iPhone home-screen Web workflow, save/recovery tests, goals and city-policy systems. The next milestone is visual migration to 3D without destabilizing game logic.

## Decision
Keep Godot and the existing simulation/state stack. Add a dedicated procedural 3D renderer in a SubViewport and project that texture into the existing portrait board area. Touch input is converted through the 3D camera ray to the ground plane, so existing road tools still operate on the same grid state.

## Why
- Preserves current simulation and save compatibility.
- Keeps the fixed GitHub Pages/iPhone test loop.
- Allows rollback to the 2D renderer without data migration.
- Lets the team measure Web/iPhone 3D performance before committing to a full rendering rewrite.

## Rejected for this slice
- Full Unity migration: too much implementation reset before 3D viability is proven.
- Three.js rewrite: would duplicate the working simulation and persistence layer.
- Rebuilding the whole project around Node3D immediately: unnecessary blast radius.

## Risks
- Procedural per-object meshes are not the final batching architecture.
- SubViewport rendering adds GPU/memory cost.
- 3D picking must remain accurate on portrait screens.

## Exit criteria
The 3D slice is accepted only if: road placement remains usable on iPhone, city state is unchanged, Web export passes, no save regression occurs, and the visual result clearly reads as a miniature 3D city.
