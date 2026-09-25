# AXIVA ZERO E — visual evaluation pass

Title-local vertical slice, 2026-09-25. Visual target:
`docs/AXIVA_ART_BIBLE_V1.0.md` and the locked North Star image. This pass
responds to the player's observation that an underdeveloped city image makes
the road-choice experience difficult to judge.

Only `?zero=e` receives the richer visual treatment. The existing road
placement, route demand, actual car paths and bypass-driven growth remain the
mechanical source of truth. The initial city now has occupied frontage near the
congested street, but both player-created north/south bypasses remain available.

The original trial added textured grass, warmer sun and materials, road
shoulders and markings, more varied frontage, clustered trees, small parks and
sixteen visible cars. It also started with a closer camera. Those visual
changes are withdrawn in the iPhone repair candidate below. The existing
road-choice fixture and its built frontage remain.

Local verification: Godot 4.7.2 import, ZERO E 42 checks, normal zero 25,
normal playable loop 82, Web PCK export and headless PCK boot pass. These
checks verify startup and road behavior, not visual quality, frame rate or
interest. This workspace lacks a graphical display, so no post-change rendered
screenshot or iPhone trial was obtained. A before/after iPhone capture, touch
test and frame pacing check are the next gates before claiming improvement.

The original trial did not meet the photoreal target. A production art pass
would require modeled assets, composed districts, natural landscape and
device-reviewed materials. PRODUCTION_DECISION remains UNDECIDED. No App Store
or public Pages release follows from this experiment automatically.

## iPhone rendering report, 2026-09-25

The first device capture of the released visual build showed a solid black
ground shape without roads, buildings or gameplay UI. Earlier headless checks
had not exercised WebGL rendering. The precise WebGL failure is unconfirmed;
this is a failed visual/device gate, not a verified improvement. The repair
candidate removes the generated RGB ground texture, extra parcel meshes and
close camera override. It retains the E seed, road-choice simulation and a
small palette update on the inherited renderer. A fresh iPhone capture must
confirm that the city, header and tools all appear before further visual work.
