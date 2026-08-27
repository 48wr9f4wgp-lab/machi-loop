# MACHI LOOP v0.22B — Native Export Requirements

Last verified: 2026-08-26
Status: planning only; do not change export presets until v0.22A Merge Gate is complete

## Current repository state

`export_presets.cfg` currently contains only the `Web` preset. Android and iOS presets are not yet present in the shared GitHub baseline.

This is intentional for now because Codex has an unpushed v0.22A working tree. Native export configuration should be added only after that state is preserved, pushed, reviewed, and merged.

## Android

### Godot 4.7 requirements

For Android export from Windows/macOS/Linux, Godot 4.7 documentation requires:

- OpenJDK 17
- Android SDK configured in Godot Editor Settings
- Android SDK directory containing `platform-tools/adb`
- Godot export templates
- release keystore/signing configuration for release builds

Source: https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html

### Google Play target API requirement

Starting 2026-08-31, Google Play requires new mobile apps and app updates to target Android 16 / API level 36 or higher.

Source:
- https://support.google.com/googleplay/android-developer/answer/11926878
- https://developer.android.com/google/play/requirements/target-sdk

Therefore MACHI LOOP's first Play submission should be designed around target API 36 rather than building against an already-expiring target.

### v0.22B Android acceptance target

- Android export preset exists after v0.22A merge.
- Debug APK can be installed on a real Android device.
- Release-oriented configuration targets API 36 or higher.
- Package identifier is stable and reverse-DNS formatted.
- Haptics permission/configuration is explicitly verified rather than assumed.
- Main-road input, save persistence, audio, haptics, background/resume, and portrait layout are tested on device.
- Performance measurements are captured using the defined P0/P1/P3/P5 states.
- Signing secrets/keystores are not committed to Git.

## iOS

### Godot export requirement

Godot's iOS export documentation states that iOS export must be performed on a computer running macOS with Xcode installed. Godot export templates are also required. App Store Team ID and Bundle Identifier are required export settings.

Source: https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_ios.html

### Apple submission requirement in 2026

Since 2026-04-28, apps uploaded to App Store Connect must be built using Xcode 26 or later with the iOS 26 SDK or later.

Source:
- https://developer.apple.com/news/upcoming-requirements/
- https://developer.apple.com/app-store/submitting/

As of this planning date, Xcode 26.x is therefore the production submission baseline. The exact Xcode/SDK requirement must be rechecked again at Release Candidate because Apple requirements are time-sensitive.

### v0.22B iOS acceptance target

- Do not pretend Windows can complete the iOS build pipeline.
- Prepare Godot iOS export settings in a merge-safe way only after v0.22A is integrated.
- Final export/build/device deployment must be executed on macOS with Xcode.
- Use a stable Bundle Identifier and Apple Team ID outside source-controlled secrets.
- Verify portrait layout, safe areas, save lifecycle, audio session behavior, and real iPhone haptics.
- Build with an Xcode/SDK combination accepted by App Store Connect at the time of the test/release.

## Renderer/device baseline

Godot 4.7 system requirements list native mobile support including Android and iOS; MACHI LOOP currently uses the Compatibility renderer for the Web slice. Renderer changes are not part of the initial native packaging task. First obtain equivalent native behavior and measure it before deciding whether renderer migration creates enough benefit to justify risk.

Source: https://docs.godotengine.org/en/4.7/about/system_requirements.html

## Recommended execution order after v0.22A Merge Gate

1. Preserve and merge v0.22A.
2. Merge documentation/planning only if still current.
3. Add Android export preset and validate API 36 toolchain.
4. Produce/install Android debug build and run device behavior/performance checks.
5. Prepare iOS export settings without claiming device success.
6. On macOS/Xcode 26+, export/build/install to iPhone and validate real haptics/audio/lifecycle.
7. Re-run full regression and save migration tests after native configuration changes.
8. Only then decide whether native becomes the production delivery path or Web remains a development/testing surface.

## Non-goals

- No Store submission yet.
- No signing credential commit.
- No paid external service contract.
- No renderer migration merely for novelty.
- No Analytics provider SDK as part of native packaging.
- No changes to v0.22A reserved files while Codex's local work is unpushed.
