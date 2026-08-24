# MACHI LOOP

Mobile-first city simulation vertical slice.

## Core loop

1. Draw only arterial roads.
2. Local streets emerge automatically.
3. Residential / commercial / industrial buildings grow automatically.
4. Population and tax income rise.
5. Congestion appears.
6. Widen arterial roads to restore flow.
7. Reach population milestones to unlock more land.

## Current build

Vertical Slice 0.2 — GitHub Pages / iPhone deployment package.

### Input

- `幹線`: drag over the map to build arterial roads.
- `拡幅 ¥90`: tap an arterial cell to increase capacity.
- `撤去`: tap a cell to remove it.
- `停止 / 再開`: pause or resume simulation.

## iPhone deployment

This repository includes `.github/workflows/deploy-pages.yml`.
Every push to `main` builds the Godot 4.7.2 Web export and deploys it to GitHub Pages.

One-time GitHub setting:

1. Repository → Settings → Pages.
2. Build and deployment → Source → `GitHub Actions`.
3. Open Actions and confirm `Build and deploy MACHI LOOP` succeeds.
4. Open the Pages URL in Safari.

The Web preset intentionally disables Godot Web thread support for broad static-host compatibility.

## Engine

- Godot 4.7.2 stable
- GDScript
- Compatibility renderer
- Landscape touch-first UX
