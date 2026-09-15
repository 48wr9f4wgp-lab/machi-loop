# MACHI LOOP — Data & Privacy Inventory v1

Status: pre-provider baseline
Last reviewed: 2026-08-26
Product model: offline-first, no required account, premium single-purchase direction

## Privacy posture

MACHI LOOP should remain low-data by default. The game does not need identity, precise location, contacts, photos, microphone, advertising ID, or free-form user content for the v1.0 core experience.

## Local-only data

### City save
Purpose: resume gameplay.
Expected contents:
- schema version
- city simulation state
- progression state
- policy/service state
- FTUE state
- feedback settings when v0.22A is integrated
- integrity/checksum metadata

Storage: local device/browser storage through Godot persistence layer.
Transmission: **none by default**.
Retention: until user/app storage deletion or migration/replacement.
PII class: internal game state; not direct PII.

### Local settings
Purpose: user preferences.
Examples:
- SFX enabled/volume
- haptics enabled
- future reduced-motion setting if implemented

Transmission: not required. A `settings_change` analytics event may send only the approved key and normalized value if analytics is later enabled.

## Planned analytics data — provider not yet approved

The v0.22B design permits only privacy-minimal gameplay/quality telemetry such as:
- release version
- platform
- locale
- returning-user boolean
- save schema version
- city tier
- population/cash/traffic bands rather than raw save payload
- FTUE step and elapsed time
- road/policy/service action summaries
- save failure/recovery/migration outcomes
- performance bands and named test state

The analytics foundation must work as a no-op with no provider and no network dependency.

## Prohibited telemetry

Never send through gameplay analytics:
- name
- email
- postal address
- precise GPS/location
- contacts
- photos/media
- microphone/camera content
- free-form user text
- secret/token/key
- complete save file or serialized city state
- payment card data
- authentication credentials

A future pseudonymous install/session identifier, if ever needed for retention, requires a separate explicit design decision covering purpose, generation, retention, deletion, Store disclosure, and provider behavior.

## Native permissions baseline

v1.0 should request no unrelated sensitive permissions.

Potential required capability:
- Android vibration/haptic capability if native haptics are enabled.

Before final native build, inspect the generated Android manifest and iOS entitlements. Unexpected permissions/capabilities are a release blocker until explained or removed.

## Third-party SDK inventory

Current target state before provider approval:
- Analytics SDK: none
- Ads SDK: none
- Attribution SDK: none
- Account/auth SDK: none
- Social SDK: none
- Crash SDK: none yet

Any new SDK requires recording:
- provider
- version
- purpose
- data collected
- data destination
- retention controls
- privacy policy impact
- App Store privacy disclosure impact
- Google Play Data safety impact
- binary/bundle impact
- cost/license
- disable/rollback path

## Store disclosure gate

Do not complete App Store privacy answers or Google Play Data safety answers from this document alone. At Release Candidate, compare the **actual final binary, permissions, SDK inventory, and network behavior** with the then-current official Store questions.

## Deletion / account handling

No account is required for v1.0, so account-deletion flow is not expected to apply to the core product. Local game data must remain removable through normal app/browser storage deletion and any in-game reset option that is ultimately shipped.

## Analytics failure policy

- analytics failure must never block input;
- analytics failure must never block save;
- analytics failure must never change simulation results;
- no telemetry retry loop may grow without bound;
- provider-unavailable mode must degrade to no-op.
