# MACHI LOOP 3D Art Bible — v0.10 Vertical Slice

## Target
A clean, readable, stylized city diorama for portrait mobile. The first 3D slice must feel like a real miniature city, not a spreadsheet with depth.

## Camera
- Orthographic/isometric-like city view.
- Stable camera; no player camera controls in v0.10.
- Roads and buildings must remain legible at iPhone portrait size.

## Shape language
- Roads: broad, dark, continuous surfaces with a warm center marking on arterials.
- Residential: low, compact, green-roofed blocks.
- Commercial: taller cool-blue blocks with glass-like accents.
- Industrial: low/wide warm blocks with utility roof forms.
- Trees: sparse rounded foliage to break up empty parcels.
- Locked districts: desaturated ground separated by a warm district boundary.

## Palette
- Open land: #BFD7B5 / #C9DEBF
- Locked land: #D9DED7
- Arterial: #323A38
- Local road: #68736F
- Lane mark: #E8C768
- Residential roof: #65A66F
- Commercial: #6FAFC9
- Industrial: #C49A58
- UI accent: #71D0A2
- District boundary: #D6A34C

## Lighting
- Warm directional key light from upper-left.
- Soft green-grey ambient fill.
- Shadows enabled for buildings and trees.
- No cinematic bloom/DOF in the first Web slice; clarity and performance win.

## Motion
- A small number of vehicles move continuously on road cells.
- New construction keeps the existing growth feedback, projected into 3D screen space.

## Performance rule
The vertical slice may use individual procedural meshes for speed of development, but Release Candidate must migrate repeated props/roads to batched or MultiMesh rendering if profiling requires it.

## Non-goals for v0.10
- Final asset quality.
- Free camera rotation/zoom.
- Detailed pedestrians.
- Weather/day-night.
- Photorealism.
