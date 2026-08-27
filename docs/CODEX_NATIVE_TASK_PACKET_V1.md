# Codex Task Packet — Native Packaging v1

Status: queued; execute only after v0.22A Merge Gate and v0.22B foundations are reconciled
Owner role: Codex / PC-local implementation and device validation

## Goal

Produce reproducible Android and iOS native validation builds without changing MACHI LOOP gameplay semantics, while preserving Web/PWA development workflow.

## Non-goals

- No Store submission.
- No public release.
- No paid sale activation.
- No monetization model change.
- No analytics-provider account/contract creation unless separately approved.
- No gameplay/economy/progression balancing.
- No redesign of Feedback Pass.

## Preconditions

1. v0.22A local work is preserved, committed, pushed, CI-green, merged.
2. Remote outage PRs are fetched and explicitly reconciled.
3. Full existing fixture suite is green on the integration branch.
4. Final package/bundle identifier is explicitly selected; do not invent ownership-sensitive namespace.
5. Signing credentials are available locally/secret store only and are not committed.

## Android

### Environment inspection
Record before changing project files:
- OS
- Godot version
- `java -version`
- Android SDK location
- installed platform/build tools
- installed NDK if required by exact Godot version

Use current official Godot documentation for the exact engine version. Project baseline expects OpenJDK 17 unless current supported documentation says otherwise.

### Export configuration
Add an Android export preset only after toolchain inspection.
Requirements:
- target API satisfies current Google Play requirement at execution time (API 36+ based on 2026-08-26 snapshot unless superseded);
- debug/test APK generation works;
- release AAB generation path exists;
- package name is the approved identifier;
- portrait orientation matches Product Lock;
- only intended permissions are present;
- vibration/haptics capability is explicitly verified;
- no signing key/keystore/password enters Git.

### Android verification
1. export debug APK;
2. install on representative device;
3. fresh-start smoke;
4. existing-save upgrade smoke;
5. FTUE;
6. road draw/widen/bulldoze;
7. settings persistence;
8. background/resume;
9. haptics hierarchy;
10. P1/P3/P5 performance measurement;
11. inspect final manifest permissions;
12. build signed/release-like AAB without publishing.

## iOS

### Hard environment requirement
Do not attempt to fake final iOS validation on Windows. Use macOS with current required Xcode and iOS SDK.

Record:
- macOS version
- Xcode version
- iOS SDK version
- Godot version/templates
- Apple Team ID availability
- approved Bundle Identifier

### Export configuration
Add/finalize iOS export only on a valid macOS/Xcode environment.
Requirements:
- current App Store Xcode/iOS SDK minimum satisfied;
- Team ID and Bundle Identifier configured outside unsafe source-control secrets;
- portrait behavior;
- no unintended capabilities/entitlements;
- native haptics path verified;
- production save path/lifecycle verified.

### iOS verification
1. export Xcode project;
2. build with Xcode;
3. install on physical iPhone;
4. fresh-start smoke;
5. upgrade existing save;
6. FTUE;
7. road controls one-handed;
8. safe-area/notch/home-indicator inspection;
9. SFX speaker/headphone listening;
10. light/medium/strong haptic feel;
11. background/foreground and OS-kill resume;
12. P1/P3/P5 performance/thermal runs.

## Files likely in scope

Inspect before editing; exact list may change after v0.22A integration:
- `export_presets.cfg`
- platform-specific project/export configuration files created by Godot
- optional platform adapter files
- CI/release scripts if needed
- docs/evidence records

Do not casually modify domain balance files.

## Acceptance criteria

- Web export remains green.
- Android test build installs and runs.
- Android release AAB can be generated without secrets in repo.
- iOS Xcode project/build installs on real iPhone.
- save/migration/recovery remain green.
- no unintended Android permissions or iOS entitlements.
- Feedback works with unsupported-platform safe fallbacks and native haptics where supported.
- full automated regression passes after export configuration changes.
- device evidence is recorded with build SHA/version.

## Rollback

Native export preset/config changes must be isolated in a feature branch. If they break Web or regression gates, revert that branch rather than changing gameplay to satisfy platform packaging.

## Stop condition

Stop and report before any:
- App Store / Google Play submission;
- public TestFlight/production rollout beyond explicitly approved test scope;
- paid service purchase;
- release sale activation.
