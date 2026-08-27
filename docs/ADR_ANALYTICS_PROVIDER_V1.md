# ADR — Analytics Provider v1

Status: **Preferred provider selected; external integration deferred pending RC stability/privacy check**
Verified: 2026-08-26

## Context

MACHI LOOP requires privacy-minimal first-party telemetry for FTUE, progression, strategy choices, save reliability, and performance. The product is offline-first, premium-first, and does not require accounts.

The internal v0.22B architecture already targets:
- versioned event schema;
- strict property validation;
- no-op provider mode;
- no PII/full save payload;
- analytics failures never blocking gameplay/save.

## Decision

**Preferred provider: GameAnalytics.**

Reasons:
- official Godot SDK exists;
- current SDK requirements support Godot 4.5+;
- platform support includes iOS, Android, Web, Windows, macOS, Linux in the current Godot integration documentation;
- game-specific event/funnel/retention tooling fits MACHI LOOP better than a generic web-only analytics stack;
- official SDK/repository uses an adapter-friendly singleton integration model;
- health/performance events exist, though MACHI LOOP should still keep its own local performance monitor as the canonical raw measurement layer.

Official references:
- https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/game-engine-sdks/godot/
- https://github.com/GameAnalytics/GA-SDK-GODOT
- https://docs.gameanalytics.com/event-tracking-and-integrations/sdks-and-collection-api/sdks-overview/

## Important current risk

The Godot Asset Store entry for GameAnalytics 3.1.0 was updated 2026-07-23 and is currently marked **unstable** by the publisher/store metadata.

Reference:
- https://store.godotengine.org/asset/gameanalytics/gameanalytics/

Therefore:
- do **not** make the game runtime depend on the SDK now;
- do **not** put provider keys/secrets in source control;
- retain no-op adapter as the default;
- re-check the latest SDK release/stability and Store/privacy impact at RC/native integration time;
- if the SDK remains unsuitable, preserve the internal event schema and swap provider without changing game/domain logic.

## User identity policy

GameAnalytics can issue a randomized user ID and also supports external user IDs. MACHI LOOP should **not** provide an external identity by default.

If pseudonymous retention identity is enabled later:
- use provider-generated/randomized install identity rather than email/account identity;
- document purpose and retention;
- reflect actual behavior in Apple/Google privacy disclosures;
- provide a disable/deletion strategy appropriate to the provider and product.

## Health/performance policy

GameAnalytics supports optional health/performance data. MACHI LOOP should not blindly enable full hardware/memory tracking.

Canonical flow:
1. local `PerformanceMonitor` measures named P1/P3/P5 state;
2. game converts measurements into coarse approved bands;
3. analytics adapter may send only approved summary properties;
4. raw hardware identifiers or unnecessary device details are not required for v1.0 analysis.

## Secrets/configuration

Provider game key / secret key are configuration secrets for the analytics service and must not be committed to the repository.

Final integration must use an approved secure configuration mechanism appropriate to the target platform/build pipeline. The repository static audit should fail obvious credential patterns.

## Alternatives

### Firebase Analytics
Not selected as the primary game analytics layer at this stage because MACHI LOOP's highest-value questions are game progression/FTUE/economy/retention oriented and the existing architecture benefits from a game-specific provider. Firebase Crashlytics may still be considered separately for native crash reporting after native packaging exists.

### PostHog / generic product analytics
Useful for product/web analysis, but not preferred over a dedicated game analytics provider for the first public game release.

### No external analytics
Acceptable for internal/dev builds. Not preferred for public release because it would make retention, FTUE drop-off, and field reliability largely guesswork.

## Acceptance before enabling provider

- [ ] v0.22A merged and stable.
- [ ] analytics foundation merged and integrated through adapter only.
- [ ] latest GameAnalytics Godot SDK stability/version rechecked.
- [ ] license and binary impact recorded.
- [ ] no provider secret committed.
- [ ] event dictionary reviewed.
- [ ] network failure proven non-blocking.
- [ ] iOS/Android/Web build compatibility verified.
- [ ] final Apple privacy / Google Data safety impact documented.
- [ ] explicit user approval obtained before connecting/creating any external production analytics service if required by project policy.
