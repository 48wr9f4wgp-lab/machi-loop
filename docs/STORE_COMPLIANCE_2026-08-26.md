# MACHI LOOP — Store Compliance Snapshot

Last verified: 2026-08-26
Freshness class: fast — re-verify at Release Candidate
Scope: Japan-first iOS / Android release

> This is a planning snapshot, not submission authorization. Store rules must be checked again against the final binary and submission date.

## Apple App Store

### Build requirement
As of 2026-04-28, apps uploaded to App Store Connect must be built with **Xcode 26 or later** using the **iOS 26 SDK or later** for iOS apps.

Official source:
- https://developer.apple.com/news/upcoming-requirements/

### Godot iOS export requirement
Godot iOS export must be performed from a **macOS computer with Xcode installed**. The Godot export templates are also required. App Store Team ID and Bundle Identifier are required in the export configuration.

Official source:
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html

### Privacy
Apple requires app privacy information in App Store Connect, including data practices of integrated third-party partners. A privacy policy URL is required for iOS apps.

Official sources:
- https://developer.apple.com/app-store/app-privacy-details/
- https://developer.apple.com/help/app-store-connect/reference/app-privacy/

### Age rating
Apple moved to its updated age-rating system in 2026. Final age-rating answers must be completed in App Store Connect against the final content set.

Official source:
- https://developer.apple.com/news/upcoming-requirements/

### MACHI LOOP pre-RC actions
- [ ] Obtain/use a Mac capable of Xcode 26+.
- [ ] Install final supported Godot export templates.
- [ ] Define final Bundle Identifier.
- [ ] Configure Apple developer Team ID/signing.
- [ ] Export Xcode project.
- [ ] Build/install on physical iPhone.
- [ ] Verify safe areas, background/resume, save, audio, haptics, performance.
- [ ] Record final SDK/third-party inventory.
- [ ] Publish a privacy policy URL before submission.
- [ ] Complete App Privacy answers from actual data behavior.
- [ ] Complete current age-rating questions.
- [ ] Prepare truthful icon/screenshots/description.

## Google Play

### Target API requirement
Starting **2026-08-31**, new apps and app updates submitted to Google Play must target **Android 16 / API level 36 or higher** (standard phone/tablet apps). This date is five days after this snapshot and therefore should be treated as the effective project requirement unless the submission plan changes and an official extension applies.

Official source:
- https://support.google.com/googleplay/android-developer/answer/11926878

### Publishing format
New Google Play apps are required to publish using **Android App Bundle (AAB)**.

Official sources:
- https://developer.android.com/guide/app-bundle
- https://support.google.com/googleplay/android-developer/answer/9844679

### Godot Android toolchain
Current Godot documentation recommends **OpenJDK 17** for Windows/macOS/Linux Android export and requires the Android SDK. The exact Android SDK/Build Tools/NDK versions must be re-checked against the Godot version used for the final native build.

Official source:
- https://docs.godotengine.org/en/latest/tutorials/export/exporting_for_android.html

### Data safety
Google Play requires developers to complete the Data safety form for published apps. Even apps that collect no user data must complete the form and provide a privacy policy link; final answers must include third-party SDK behavior.

Official source:
- https://support.google.com/googleplay/android-developer/answer/10787469

### MACHI LOOP pre-RC actions
- [ ] Install/verify JDK and Android SDK toolchain on the build PC.
- [ ] Target API 36+ unless newer current requirement supersedes it.
- [ ] Create deterministic package name before public release.
- [ ] Add Android export preset.
- [ ] Produce local test APK for device validation.
- [ ] Produce signed release AAB for Play pipeline validation.
- [ ] Verify only intended permissions/capabilities exist.
- [ ] Verify native haptic/vibration behavior and required permission/configuration.
- [ ] Test lifecycle/background/resume/save on representative Android device.
- [ ] Publish privacy policy URL before store release.
- [ ] Complete Data safety answers from actual final data/SDK behavior.
- [ ] Prepare truthful store listing assets.

## Monetization / premium direction

The locked v1.0 direction is premium single-purchase. Final price is intentionally **not locked** here. Price must be decided from current competitor/store research near RC.

Do not introduce ads, gacha, energy, subscription, or IAP solely to satisfy a store checklist. Any monetization model change requires a game-specific product decision before implementation.

## Submission authorization

The following are deliberately outside automatic development execution and require explicit user approval:
- public App Store submission;
- public Google Play submission;
- setting a paid live price / beginning sales;
- paid external service contracts;
- irreversible production rollout.

## RC re-verification

At RC, repeat from official sources:
1. Apple SDK/Xcode minimum.
2. Apple review/privacy/age-rating requirements.
3. Google target API requirement.
4. Google AAB/signing/Data safety requirements.
5. Godot export requirements for the exact engine version.
6. Actual final SDK/permission/network inventory.
