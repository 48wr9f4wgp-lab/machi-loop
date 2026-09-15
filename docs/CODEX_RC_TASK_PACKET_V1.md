# Release Candidate Audit / Fix-Only Task Packet v1

Status: final heavy-work packet after Release Readiness + native validation.

## Goal
Produce evidence for a Release Candidate and leave only specific reproducible findings. No opportunistic features.

## Freeze rule
Record branch, candidate SHA, VERSION, Godot and Web/Android/iOS toolchains. After functional freeze, changes are allowed only for Hard Gates, scored audit deductions, reproducible regression/performance/accessibility/Store problems, or required release engineering. Every fix names its evidence.

## Execution
Run full functional/FTUE/save/migration suite; device QA on Web/PWA and native targets; P1/P3/P5 performance; accessibility/localization; privacy/security/license/Store audit; FINAL_AUDIT_SCORECARD. Fix smallest safe diff, targeted test, relevant regression and device re-check.

## Exit
All P0/P1 closed, visual/product score >=90, no Hard Gate, final candidate SHA/artifacts/evidence recorded. Public submission, paid activation and external production rollout remain explicit-approval actions.
