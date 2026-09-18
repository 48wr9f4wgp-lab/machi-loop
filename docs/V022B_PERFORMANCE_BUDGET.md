# MACHI LOOP v0.22B — Performance Budget & Device Test Plan

Status: provisional acceptance budget; must be calibrated with real-device measurements
Scope: iPhone PWA/Web first, then native iOS/Android

## Objective

Performance is a product feature. MACHI LOOP is a portrait 3D city simulator with autonomous growth, so the main risk is gradual degradation as city tier, geometry count, effects, and vehicle count increase.

The purpose of this document is not to optimize blindly. It defines what to measure, where to measure it, and when a regression blocks the next release stage.

## Test states

Every performance run should use deterministic or fixture-backed city states:

1. `P0_EMPTY` — fresh city before first road
2. `P1_FTUE` — first main road + initial growth
3. `P2_SMALL` — small city / early unlocked district
4. `P3_MID` — mid-tier city with representative services/policy
5. `P4_DENSE` — late-tier dense city with high building/traffic count
6. `P5_METRO` — metropolitan/end-state stress fixture

Performance numbers without a named city state are not comparable.

## Frame-time targets

### Primary target
- Target refresh: 60 FPS where the device/browser can sustain it.
- Preferred typical frame time: <= 16.7 ms average in ordinary play.
- Provisional acceptance: p95 frame time <= 25 ms in `P3_MID` on baseline supported hardware.

### Hard regression signals
- Sustained gameplay below 30 FPS for >= 5 seconds in normal camera view.
- Repeated input stalls >= 100 ms during road drag/commit.
- Visible freeze during save, goal reward, tier-up, or scene restoration.
- Performance worsening substantially from `P3_MID` to `P4_DENSE` without an identified scalability plan.

These are project thresholds, not claims about platform guarantees.

## Startup targets

Measure from app/page launch to first responsive gameplay input.

Provisional targets:
- Warm launch: <= 3 s on baseline iPhone.
- Cold launch: <= 5 s on baseline iPhone under normal network/cache conditions for PWA/Web.
- Native targets are re-baselined after native packaging exists.

Record separately:
- HTML/shell load
- WASM/PCK load where observable
- Godot scene initialization
- save load/migration/recovery
- first interactive frame

## Interaction latency

Critical interactions:
- road drag preview
- arterial commit
- widen
- bulldoze
- settings toggle
- pause/resume

Acceptance intent:
- pointer feedback should appear in the same rendered frame whenever feasible.
- no critical interaction should wait for analytics/network.
- save/feedback work must not block road preview.

## Rendering scalability

Track per named city state:
- visible MeshInstance3D count
- total generated geometry node count
- vehicle count
- dynamic/animated object count
- shadow-casting object count
- material count
- viewport resolution
- draw calls if available through profiler

Do not impose a fake universal mesh-count limit before measurement. The v0.22B task is to obtain baselines and identify the first dominant bottleneck.

Optimization priority if profiling proves necessary:
1. repeated static props/roads → batching/MultiMesh
2. shadow casters → reduce/distance/tier
3. ambient prop density
4. viewport/render scale
5. expensive material/post effects
6. vehicle/ambient animation density

Do not cut gameplay clarity before decorative cost.

## Memory / stability

Web/iOS memory reporting varies by runtime, so use all available evidence rather than pretending a single universal number is reliable.

Record where available:
- process/runtime memory
- WASM heap indicators
- texture/resource size
- peak during save/load
- peak during `P5_METRO`
- reload/crash/OOM symptoms

Hard block:
- reproducible browser tab reload/OOM/crash under supported normal play.
- save corruption caused by memory pressure or lifecycle interruption.

## Thermal / battery observation

For real-device 10-minute and 20-minute runs record:
- device model
- OS version
- Web/PWA/native
- starting battery percentage
- ending battery percentage
- subjective thermal state: cool / warm / hot / throttling suspected
- FPS at start and end

Subjective thermal notes are diagnostic, not a scientific battery benchmark.

## Audio / haptic performance

For v0.22A/v0.22B verify:
- SFX generation does not cause a visible frame hitch on first play.
- repeated road commits respect cooldown and do not create unbounded audio nodes.
- haptic adapter no-op path on Web has negligible cost.
- settings save does not stall input.

If runtime PCM synthesis produces first-use hitch or unacceptable memory/CPU cost, move production SFX to licensed/prebuilt assets in the later Audio Production Pass.

## Instrumentation design

Create a platform-independent `PerformanceMonitor`/adapter rather than scattering counters through gameplay code.

Minimum locally recorded metrics:
- release version
- platform
- named performance state
- elapsed sample window
- average FPS
- minimum FPS or worst-frame bucket
- slow-frame count/rate
- startup duration
- geometry count
- city tier

Optional only if platform exposes reliably:
- memory
- draw calls
- GPU time
- CPU frame time

Analytics transmission is separate from measurement. Local measurement must work with analytics disabled/no provider.

## Real-device matrix — initial

### Required before RC
- baseline current iPhone used for daily PWA testing
- one older/lower-performance supported iPhone if available
- one representative Android mid-range device
- native iOS build once packaging exists
- native Android build once packaging exists

### Each device
Run at least:
- P1_FTUE: 5 minutes
- P3_MID: 10 minutes
- P5_METRO: 10 minutes
- suspend/background/resume
- save/relaunch

## Performance regression gate

A change is blocked when it introduces any of:
- new reproducible <30 FPS sustained normal-play segment
- input hitch >=100 ms on critical road interaction
- startup regression >20% without product justification
- OOM/reload/crash
- save/recovery regression
- material visual gain that causes disproportionate frame/thermal cost

## v0.22B Codex acceptance criteria

1. Add measurement instrumentation without changing simulation balance.
2. Produce deterministic P1/P3/P5 test states or repeatable setup instructions.
3. Capture baseline on local desktop Web as a sanity check.
4. Capture baseline on actual iPhone PWA.
5. Report bottlenecks; do not optimize without profiler evidence.
6. Keep analytics provider integration optional/no-op.
7. Preserve all existing Functional Build, Save, Render, Feedback fixtures.
8. Native optimization is deferred until native packages exist.
