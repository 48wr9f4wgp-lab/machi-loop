# MACHI LOOP — QA Matrix v1

Status: pre-RC execution matrix
Scope: Web/PWA, Android native, iOS native

## Severity
- **P0**: startup/input/progression/save/payment/privacy failure; release blocker.
- **P1**: major gameplay or UI failure; release blocker.
- **P2**: noticeable defect with workaround.
- **P3**: cosmetic/minor.

## Core smoke
| ID | Test | Expected | Severity |
|---|---|---|---|
| SMK-01 | Launch new game | Playable city appears | P0 |
| SMK-02 | Draw first main road | Road commits once; cost/reward correct | P0 |
| SMK-03 | Observe first growth | Local development auto-grows | P0 |
| SMK-04 | Widen road | Cost/capacity update correctly | P1 |
| SMK-05 | Bulldoze road | State remains valid | P1 |
| SMK-06 | Change policy | Cost/effect applies once | P1 |
| SMK-07 | Toggle city service | Slot/cost/effect applies | P1 |
| SMK-08 | Reach goal | Reward once | P1 |
| SMK-09 | Reach tier-up | Unlock once; save valid | P1 |
| SMK-10 | Save/relaunch | State restores | P0 |

## FTUE / Save
- Fresh install begins at first actionable instruction.
- Interrupted FTUE resumes correctly and rewards do not duplicate.
- Developed old saves do not re-enter FTUE.
- Current save, legacy migration, corrupt-primary backup recovery, settings persistence and app-upgrade preservation are P0/P1 gates.

## Feedback / UI / Accessibility
- Road/goal/tier feedback hierarchy remains distinct.
- SFX OFF and Haptics OFF preserve visual meaning.
- Rapid actions cannot spam feedback.
- No primary UI under notch/Dynamic Island/home indicator.
- Japanese glyphs render correctly; critical touch targets are reliable one-handed.
- Important states remain understandable in grayscale and without audio/haptics.
- Reduced Motion decision must be closed before RC.

## Lifecycle / Performance
- Background 5 s / 5 min, OS kill, PWA reload and cache update must preserve safe state.
- P1_FTUE, P3_MID and P5_METRO are measured.
- No sustained <30 FPS normal segment for >=5 s.
- No recurring >=100 ms critical road-input stall.
- Dense save/reload cannot lose data or freeze unacceptably.

## Native gates
Android: release-like APK/AAB build, install, launch/play/save, permissions and lifecycle.
iOS: macOS/Xcode export, install, launch/play/save, haptics, interruptions and safe areas.

## Exit criteria
- all P0 PASS;
- all P1 PASS or explicitly removed from supported scope;
- P2/P3 triaged;
- automated fixtures green on final candidate SHA;
- Web/PWA + Android + iOS evidence retained.
