# MACHI LOOP — QA Matrix v1

Status: pre-RC execution matrix
Scope: Web/PWA, Android native, iOS native

## Purpose

Automated fixtures prove deterministic rules. This matrix covers the remaining behavior, lifecycle, device, accessibility, and release risks that fixtures alone cannot close.

## Severity

- **P0**: startup/input/progression/save/payment/privacy failure; release blocker.
- **P1**: major gameplay or UI failure with broad impact; release blocker until fixed or explicitly descoped.
- **P2**: noticeable defect with workaround; polish/RC decision.
- **P3**: cosmetic/minor.

## Core smoke — every candidate build

| ID | Test | Expected | Severity |
|---|---|---|---|
| SMK-01 | Launch new game | Playable city appears; no fatal error | P0 |
| SMK-02 | Draw first main road | Road commits once; cost/reward correct | P0 |
| SMK-03 | Observe first growth | Local development appears without manual placement | P0 |
| SMK-04 | Widen road | Cost applies; capacity/traffic improves as designed | P1 |
| SMK-05 | Bulldoze road | Refund applies; state remains valid | P1 |
| SMK-06 | Change policy | Cost/effect applies once | P1 |
| SMK-07 | Toggle city service | Slot/cost/effect applies | P1 |
| SMK-08 | Reach goal | Reward once; no duplicate feedback | P1 |
| SMK-09 | Reach tier-up | Tier unlock once; save remains valid | P1 |
| SMK-10 | Save/relaunch | State restores exactly enough to continue | P0 |

## FTUE

| ID | Test | Expected | Severity |
|---|---|---|---|
| FTU-01 | Fresh install | FTUE begins from first actionable instruction | P1 |
| FTU-02 | Interrupt after first road | Relaunch resumes correct FTUE step | P1 |
| FTU-03 | Interrupt after first reward | Relaunch does not replay reward incorrectly | P1 |
| FTU-04 | Load developed old save | FTUE is considered complete | P1 |
| FTU-05 | Complete FTUE | Core loop is playable without tutorial lock | P0 |

## Save / migration / recovery

| ID | Test | Expected | Severity |
|---|---|---|---|
| SAV-01 | Current schema normal save | Atomic write/read succeeds | P0 |
| SAV-02 | Supported legacy fixture | Migrates forward and remains playable | P0 |
| SAV-03 | Corrupt primary, valid backup | Backup recovery succeeds | P0 |
| SAV-04 | Interrupted lifecycle during save | No unrecoverable corruption | P0 |
| SAV-05 | Settings-only save | Feedback settings persist without game progress | P1 |
| SAV-06 | Upgrade app over existing save | No reset/data loss | P0 |

## Feedback

| ID | Test | Expected | Severity |
|---|---|---|---|
| FDB-01 | Road commit | Light/short acknowledgement | P2 |
| FDB-02 | Goal complete | Distinct medium success | P2 |
| FDB-03 | Tier-up | Strongest normal success feedback | P2 |
| FDB-04 | SFX OFF | No audio request/output; visual meaning remains | P1 |
| FDB-05 | Haptics OFF | No haptic request/output; visual meaning remains | P1 |
| FDB-06 | Rapid repeated actions | No audio/haptic spam or runaway nodes | P1 |

## UI / device

Required portrait device classes:
- narrow supported iPhone width
- baseline daily-test iPhone
- larger iPhone
- representative Android mid-range

| ID | Test | Expected | Severity |
|---|---|---|---|
| UI-01 | Safe area top | No HUD/CTA under Dynamic Island/notch | P0 |
| UI-02 | Safe area bottom | No critical CTA under home indicator | P0 |
| UI-03 | Japanese font | No tofu/missing glyphs | P0 |
| UI-04 | Settings modal | Opens/closes without blocking city controls afterward | P1 |
| UI-05 | Policy/service overlays | No overlapping critical controls | P1 |
| UI-06 | Dense city | HUD remains readable against city background | P1 |
| UI-07 | Touch targets | Critical controls reliably tappable one-handed | P1 |
| UI-08 | Orientation change attempt | Product remains in supported portrait behavior | P2 |

## Accessibility

| ID | Test | Expected | Severity |
|---|---|---|---|
| ACC-01 | Grayscale/color-weak inspection | Important states still have text/icon/shape cue | P0 |
| ACC-02 | Sound disabled | Critical success/error state still understandable | P1 |
| ACC-03 | Haptics disabled | Critical state still understandable | P1 |
| ACC-04 | Reduced Motion decision | Implemented or explicitly justified before RC | P1 |
| ACC-05 | Text expansion/pseudo-localization | Critical UI does not clip disastrously | P1 |

## Lifecycle

| ID | Test | Expected | Severity |
|---|---|---|---|
| LIFE-01 | Background 5 s | Resume without reset | P0 |
| LIFE-02 | Background 5 min | Resume/save consistent | P0 |
| LIFE-03 | OS kills app after background | Last committed safe save resumes | P0 |
| LIFE-04 | PWA hard reload | Current save and settings restore | P0 |
| LIFE-05 | Browser cache update | New version loads without persistent stale shell | P1 |

## Performance

Run against named P1_FTUE / P3_MID / P5_METRO states.

| ID | Test | Expected | Severity |
|---|---|---|---|
| PERF-01 | 5 min P1 | No sustained <30 FPS / input stall | P1 |
| PERF-02 | 10 min P3 | p95/thermal within provisional budget | P1 |
| PERF-03 | 10 min P5 | Stress behavior measured; no crash/OOM | P0 |
| PERF-04 | Road drag under dense city | No recurring >=100 ms critical stall | P1 |
| PERF-05 | First SFX playback | No visible hitch | P2 |
| PERF-06 | Save/reload dense city | No data loss / unacceptable freeze | P0 |

## Native Android

| ID | Test | Expected | Severity |
|---|---|---|---|
| AND-01 | Release-like APK/AAB build | Build succeeds with approved SDK config | P0 |
| AND-02 | Install on device | Launch/play/save succeeds | P0 |
| AND-03 | Haptics | Light/medium/strong hierarchy is acceptable | P2 |
| AND-04 | Permission inspection | Only required permissions present | P0 |
| AND-05 | Back/lifecycle | No unintended exit/data loss | P0 |

## Native iOS

| ID | Test | Expected | Severity |
|---|---|---|---|
| IOS-01 | Export from macOS/Xcode | Xcode project/build succeeds | P0 |
| IOS-02 | Install on iPhone | Launch/play/save succeeds | P0 |
| IOS-03 | Haptics | Semantic hierarchy feels intentional, not buzzy/spammy | P2 |
| IOS-04 | Interruptions/background | Resume/save safe | P0 |
| IOS-05 | Safe areas | All primary controls visible and tappable | P0 |

## Exit criteria

Release Candidate requires:
- all P0 PASS;
- all P1 PASS or explicitly removed from supported scope before RC;
- P2/P3 defects triaged with owner/decision;
- automated fixtures green on the final candidate SHA;
- Web/PWA + Android native + iOS native evidence attached to the audit record.
