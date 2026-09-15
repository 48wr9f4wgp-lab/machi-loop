# MACHI LOOP — Data & Privacy Inventory v1

Status: pre-provider baseline
Product: offline-first, no required account, premium direction

## Privacy posture
MACHI LOOP remains low-data by default. Core play does not require identity, precise location, contacts, photos, microphone, advertising ID or free-form user content.

## Local data
City save: schema, simulation/progression, policy/service, FTUE, feedback settings, integrity metadata. Transmission: none by default.
Settings: SFX/volume, haptics and future reduced-motion preference. Transmission not required.

## Allowed telemetry shape if later enabled
Release/platform/locale, returning boolean, save schema, city tier, coarse population/cash/traffic bands, FTUE step/time, road/policy/service summaries, save outcomes, performance bands.
Analytics must remain adapter-based and no-op capable.

## Prohibited telemetry
Name, email, postal address, precise GPS/location, contacts, photos/media, mic/camera content, free-form text, secrets/tokens/keys, complete save payload, payment card or authentication credentials.

## Native permissions
No unrelated sensitive permissions. Inspect final Android manifest and iOS entitlements; unexplained capabilities are release blockers.

## Third-party SDK gate
Before any SDK is enabled record provider/version/purpose/data/destination/retention/privacy disclosures/binary impact/cost/license/rollback path.

## Store disclosure gate
Final App Store privacy and Google Play Data safety answers must be based on the actual final binary, permissions, SDK inventory and network behavior—not this document alone.

Analytics failure must never block input, save or simulation and may not create unbounded retries.
