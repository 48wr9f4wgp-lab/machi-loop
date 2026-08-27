# ADR — Observability / Crash Reporting Strategy v1

Status: provider strategy selected; final native-provider enablement deferred to RC evidence
Verified: 2026-08-26

## Context

Public MACHI LOOP needs enough field evidence to identify startup crashes, save/migration failures, hangs/ANRs where available, and version/device-specific regressions. At the same time, every extra native SDK increases build complexity, privacy declarations, binary size, and Store risk.

The project now has a provider-agnostic observability foundation with:
- bounded 32-entry gameplay breadcrumbs;
- strict code/severity/context allowlists;
- explicit PII/secret rejection;
- no-op reporter by default;
- no gameplay/save dependency on reporting success.

## Decision

### Phase 1 — Prefer one provider footprint
If GameAnalytics is approved and stable enough for the final Godot/native build, use its error reporting for the first public telemetry pass **only if actual native testing proves it provides sufficient crash/error evidence**.

Rationale:
- it is already the preferred gameplay analytics provider;
- reducing SDK count reduces privacy/build integration surface;
- GameAnalytics supports error events and native unhandled-error reporting capabilities in its SDK documentation.

### Phase 2 — Crashlytics contingency
If RC testing shows the selected GameAnalytics integration cannot provide the release-quality crash-free/session, Android ANR, stack/symbolication, or platform-specific reliability evidence required by the project, add Firebase Crashlytics as a **separate native observability decision**, not as an automatic dependency.

Crashlytics is strongest for native Android/iOS crash reporting and Android ANR reporting, but adding it means:
- another SDK/integration path;
- additional privacy/Data safety/App Privacy review;
- Godot-native bridge/plugin work may be required because Firebase's primary official platform integrations are native/Unity rather than a first-party Godot SDK path;
- extra binary/build complexity.

## What MACHI LOOP must report

Approved diagnostic concepts:
- release/build version;
- platform/OS class where provider supplies it appropriately;
- current scene/screen;
- city tier;
- save schema version;
- bounded recent action breadcrumbs;
- normalized error code/severity/stage;
- crash/non-fatal/ANR signal when supported.

## What must never be attached

- name/email/address;
- precise location;
- free-form user text;
- save file or serialized city state;
- provider/API secrets;
- purchase credentials;
- unbounded logs;
- arbitrary memory dumps containing user/private data.

## Error-code policy

Use stable machine-readable codes such as:
- `save_write_failed`
- `save_recovery_failed`
- `migration_failed`
- `render_initialization_failed`
- `native_export_runtime_error`

Do not send raw exception/user-facing text as analytics properties unless a provider's crash system captures platform stack/error material under its documented privacy behavior and the final privacy audit approves it.

## Breadcrumb policy

Maximum 32 semantic breadcrumbs. Examples:
- `session_start`
- `arterial_commit`
- `road_widen`
- `policy_change`
- `service_toggle`
- `goal_complete`
- `tier_up`
- `save_begin`
- `save_complete`

Do not breadcrumb every simulation tick or frame.

## RC provider gate

Before enabling production crash reporting:
- [ ] exact provider/SDK version recorded;
- [ ] license/cost reviewed;
- [ ] native Web/Android/iOS compatibility verified;
- [ ] network failure/offline behavior verified;
- [ ] final data fields/destinations inventoried;
- [ ] Apple privacy / Google Data safety impact recorded;
- [ ] crash/nonfatal evidence tested with a controlled test failure on non-production data;
- [ ] no secret committed;
- [ ] actual value over no-op mode demonstrated.

## Rollback

Reporting remains behind the provider adapter. If a provider creates crashes, Store/privacy risk, or disproportionate integration cost, disable/remove the provider without modifying simulation, save, UI, or gameplay rules.
