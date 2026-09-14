# MACHI LOOP v0.22B — Analytics Event Dictionary

Status: design only; provider integration is not authorized by this document
Version: event schema 1
Privacy class: anonymous/pseudonymous operational gameplay telemetry only

## Principles

- No name, email, address, precise location, free-form text, save-file contents, secrets, or tokens.
- Event names use `lower_snake_case`.
- Dynamic values belong in properties, never inside event names.
- Do not emit high-frequency simulation-tick telemetry. Prefer meaningful state transitions and session summaries.
- Every event carries `event_schema_version=1`, `release_version`, `platform`, and `locale` where available.
- Provider SDK selection is a separate decision requiring privacy, bundle-size, cost, and Store review.
- Default analytics adapter may be a no-op until a provider is approved.

## Primary questions

1. Do new players understand the main-road → autonomous-growth loop?
2. Where does FTUE fail or stall?
3. Does the player solve congestion by building/widening, or churn after traffic pressure rises?
4. Which policy/service choices are used and retained?
5. How quickly do players reach each city tier/district?
6. Are economy sinks/sources producing bankruptcy or runaway surplus?
7. Are save/recovery/migration failures occurring?
8. Which device tiers experience slow frames or poor startup?
9. Do players disable SFX/haptics after trying them?

## Minimum launch event set

### Session

#### `session_start`
Trigger: playable main scene becomes ready.
Properties:
- `release_version: string`
- `platform: string`
- `locale: string`
- `returning_user: bool`
- `save_schema_version: int`
- `city_tier: int`
- `population_band: string`

#### `session_end`
Trigger: app lifecycle exit/background where reliable, otherwise next-session inferred summary.
Properties:
- `duration_sec: int`
- `actions_count: int`
- `roads_committed: int`
- `goals_completed: int`
- `tier_delta: int`
- `cash_delta_band: string`

### FTUE

#### `ftue_start`
Properties: none beyond common context.

#### `ftue_step`
Properties:
- `step_id: string`
- `elapsed_sec: int`

Allowed initial step ids:
- `first_main_road`
- `first_growth_seen`
- `first_goal_complete`
- `first_traffic_problem`
- `first_management_choice`

#### `ftue_complete`
Properties:
- `total_sec: int`

### Core city actions

#### `arterial_commit`
Trigger: successful main-road commit only.
Properties:
- `cells: int`
- `cost: int`
- `cash_after_band: string`
- `traffic_before_band: string`

#### `road_widen`
Properties:
- `cost: int`
- `traffic_before_band: string`

#### `road_bulldoze`
Properties:
- `refund: int`
- `maintenance_delta_band: string`

#### `action_blocked`
Trigger: a meaningful attempted action is rejected.
Properties:
- `action: string`
- `reason: string`

Allowed reasons initially:
- `insufficient_cash`
- `locked_area`
- `invalid_cell`

### Progression

#### `city_goal_complete`
Properties:
- `goal_id: string`
- `reward: int`
- `elapsed_session_sec: int`

#### `city_tier_up`
Properties:
- `from_tier: int`
- `to_tier: int`
- `population: int`

#### `district_unlock`
Properties:
- `district_index: int`
- `population: int`

### Strategy

#### `policy_change`
Properties:
- `from_policy: string`
- `to_policy: string`
- `cost: int`

Allowed policy values:
- `none`
- `homes`
- `jobs`
- `flow`

#### `service_toggle`
Properties:
- `service_id: string`
- `enabled: bool`
- `active_service_count: int`
- `service_slot_limit: int`

### Settings / game feel

#### `settings_change`
Properties:
- `key: string`
- `value: string`

Allowed keys initially:
- `sfx_enabled`
- `haptics_enabled`

Do not send arbitrary setting keys or user-entered values.

### Reliability

#### `save_write_failed`
Properties:
- `schema_version: int`
- `stage: string`

#### `save_recovered`
Properties:
- `schema_version: int`
- `source: string` (`backup` or other explicit recovery source)

#### `migration_success`
Properties:
- `from_schema: int`
- `to_schema: int`

#### `migration_failed`
Properties:
- `from_schema: int`
- `target_schema: int`
- `stage: string`

### Performance

#### `performance_summary`
Emit at most once per session or at explicitly defined checkpoints.
Properties:
- `sample_window_sec: int`
- `avg_fps_band: string`
- `slow_frame_rate_band: string`
- `startup_ms_band: string`
- `city_tier: int`
- `geometry_band: string`
- `device_class: string`

No raw device identifier is required.

## Derived funnels

### FTUE funnel
`session_start → ftue_start → first_main_road → first_growth_seen → first_goal_complete → first_traffic_problem → first_management_choice → ftue_complete`

### Core problem-solving funnel
`traffic_pressure_rises → arterial_commit or road_widen → next performance/traffic state`

Note: do not create a high-frequency `traffic_pressure_rises` event for every tick. Derive or rate-limit it at threshold crossings only if needed after initial testing.

### Progression funnel
`city_goal_complete → district_unlock → city_tier_up`

## KPI candidates

- FTUE completion rate
- Time to first main road
- Time to first autonomous growth
- Time to first goal completion
- Time to first congestion response
- D1 / D7 / D30 after public release
- Sessions per user
- Median session duration
- District/tier reach rate
- Policy/service distribution
- Insufficient-cash blocked-action rate
- Save failure/recovery rate
- Crash-free sessions once crash reporting exists
- Performance summary by platform/device class/city tier

## Guardrails

No design change should be accepted on one metric alone. Examples:
- More reward feedback: verify next-action conversion **and** abandonment/performance.
- Faster growth: verify progression **and** economy pressure.
- More dense 3D assets: verify visual quality **and** FPS/heat/memory.

## Implementation acceptance criteria for future v0.22B code

- Analytics interface is separated from game/domain logic by an adapter.
- Default/no-provider mode runs without network calls or errors.
- Event schema is validated in tests.
- Unknown properties are rejected or explicitly versioned.
- No PII or full save payload can enter events.
- High-frequency events are rate-limited or summarized.
- Analytics failures never block gameplay or saving.
- Provider SDK is not added until privacy/cost/bundle review is approved.
