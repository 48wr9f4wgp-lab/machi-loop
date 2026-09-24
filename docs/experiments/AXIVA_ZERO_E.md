# AXIVA ZERO E — road choice and real flow

Title-local working hypothesis, 2026-09-24. Baseline: D Pages build
`68bc91bfdaaa803f412ba6b473014f4b35ad5cf8`. D's four-times-area
experiment did not make the user want to choose another district after nearby
connections. Map size alone was not proven to be the cause or cure.

Question: when growth creates a visible bottleneck, does drawing a useful
alternative road produce a satisfying, understandable change that makes the
player want to try another layout? This is a one-intervention test, not a claim
that the full repeatable city loop or Greenlight has passed.

Activation: `?zero=e` on Web, `-- --zero-e` in native development runs. Starts
with a compact 16x22 populated city and one congested east-west arterial. It
uses the existing road input, scene, recovery test isolation and save safety.
The experiment replaces the coarse recovery fixture's traffic score with a
bounded path model: actual arterial paths between west/east trip endpoints
carry demand based on occupied buildings. Each path shares the load. A tiny
cosmetic loop or disconnected road changes neither the path set nor pressure.
North and south are both viable, unmarked alternatives. Actual cars run on
the calculated paths and slow on overloaded edges. On recovery, autonomous
buildings occupy available parcels along the new path: commercial north or
residential south. The road and growth state is real, not a banner-only result.
No road quota, input lock, synthetic failure or compulsory prior mistake.

Prototype simplifications: one fixed west/east trip pair; no whole-city origin
and destination model, real-world vehicle counts or production balance. The
seed begins at the bottleneck, so it does not prove first-road-to-problem
timing. There is no new currency, permanent challenge, second-session goal or
claim of long-term replay. A solved bypass can be erased to restore pressure;
Reset restarts the isolated fixture without touching normal saves.

Acceptance for this build: both spatially separated bypass choices work through
actual touch strokes, redistribute load and produce distinct frontage growth;
one-ended and cosmetic loops do not falsely recover; deleting a bypass restores
pressure; normal/A/B/C/D and persistence regressions remain green; import,
font and Web export succeed. The device gate asks without a route hint: can the
player spot the congestion, draw a plausible alternative, see where cars and
development moved, and want to test the other solution? Record their actual
action/reaction. Automated mechanics are not evidence of delight.

Local evidence: Godot 4.7.2 import PASS, E 42 checks PASS, normal 82, A 25,
B 21, C 23+35 and D 83 checks PASS (311 total); existing subset font covers
195 required characters. CI uses the repository-pinned Godot 4.7.1 for final
PR build/export/regression. Native iOS screen, frame pacing, touch feel and
player interest remain unverified. PRODUCTION_DECISION stays UNDECIDED.

Rollback: return to D on current main; ZERO E is query-isolated and ephemeral.
No new Pages build or App Store action is authorized by implementing this code.
