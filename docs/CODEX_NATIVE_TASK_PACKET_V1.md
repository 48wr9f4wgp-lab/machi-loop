# Native Packaging Task Packet v1

Status: queued after Release Readiness integration.
Goal: reproducible Android/iOS validation builds without changing gameplay semantics; preserve Web/PWA workflow.

## Non-goals
No Store submission, public release, paid activation, monetization change or production analytics connection.

## Preconditions
Current main/fixtures green; package/bundle identifier explicitly selected; signing credentials remain local/secret-store only.

## Android
Record environment/Godot/Java/SDK. Add export configuration deliberately, target the then-current Play requirement, build release-like APK/AAB, inspect permissions, install on physical device and verify launch/core loop/save/lifecycle/audio/haptics/performance.

## iOS
Requires macOS/Xcode and Godot export templates. Configure Bundle ID/Team/signing without committing credentials, export/build/install on physical iPhone and verify safe areas/lifecycle/save/audio/haptics/performance.

## Stop condition
Native validation may prepare artifacts, but Store submission/public rollout requires explicit approval.
