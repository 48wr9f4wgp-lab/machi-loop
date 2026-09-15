# Codex Task Packet — Release Candidate Audit / Fix-Only v1

Status: final heavy-work packet
Execute after v0.22A + approved v0.22B foundations + native packaging are integrated.

## Goal

Produce evidence for a Release Candidate and leave only specific, reproducible audit findings to fix. Do not add opportunistic features.

## Freeze rule

At task start record:
- branch
- candidate base SHA
- VERSION/build identifier
- Godot version
- Web/Android/iOS toolchain versions

After functional freeze, a code change is allowed only when it:
1. fixes a Hard Gate;
2. fixes a scored final-audit deduction;
3. fixes reproducible regression/performance/accessibility/store problem;
4. is required for final release engineering.

Every fix must name the evidence that justified it.

## Phase 1 — Merge / baseline gate

- preserve any local work;
- fetch remote;
- compare branch/main;
- resolve all outstanding draft-PR dependencies deliberately;
- no blind pull/reset/clean;
- run complete automated suite;
- build Web export.

If baseline is not green, stop feature work and fix baseline first.

## Phase 2 — Functional end-to-end

Run `QA_MATRIX_V1.md` core, FTUE, save, migration, feedback and lifecycle cases.
Must prove:
- fresh city to first road/growth/reward;
- traffic pressure and recovery;
- economy pressure and recovery;
- policy/service decisions;
- all city tiers reachable;
- developed old save works;
- corruption recovery works;
- no ordinary player state is unrecoverably stuck.

## Phase 3 — Device matrix

### Web/PWA iPhone
Run P1_FTUE, P3_MID, P5_METRO.
Capture:
- FPS/p95/worst/slow-frame rate;
- critical input latency;
- startup;
- thermal notes;
- safe-area screenshots;
- Japanese font;
- save/reload/update behavior;
- sound-off/haptics-off behavior.

### Android native
Run same named states plus:
- install/update;
- background/resume;
- manifest permissions;
- native haptics;
- release-like AAB generation.

### iOS native
Run same named states plus:
- Xcode build/install;
- safe areas;
- background/OS-kill resume;
- native haptics;
- speaker/headphone SFX;
- entitlements/capabilities.

## Phase 4 — Profiling

Do not optimize from intuition.
For any performance failure:
1. reproduce on named state;
2. profile dominant CPU/GPU/render/resource source;
3. record before numbers;
4. make smallest targeted optimization;
5. record after numbers;
6. visual-regression check;
7. full relevant regression.

Optimization priority should preserve gameplay/readability before decorative density.

## Phase 5 — Visual / UX / accessibility audit

Use:
- `FINAL_AUDIT_SCORECARD_V1.md`
- `ACCESSIBILITY_GATE_V1.md`
- `LOCALIZATION_GATE_V1.md`
- latest mobile city-builder benchmark

For each score deduction output:
- screenshot/evidence;
- benchmark principle gap;
- severity;
- exact proposed fix;
- files/system;
- expected benefit;
- performance/copy-risk impact;
- verification.

Target: score >=90 and zero Hard Gates.

## Phase 6 — Privacy / observability / analytics

Verify final binary/runtime, not design documents alone:
- SDK list;
- network destinations;
- permissions/entitlements;
- analytics event schema;
- no PII/full save/free text;
- no tracked secrets;
- error reporting breadcrumbs bounded and privacy-safe;
- provider failure/offline mode cannot block save/gameplay.

## Phase 7 — Store readiness

Refresh official requirements on execution date.
Verify:
- Apple required Xcode/iOS SDK;
- Google target API;
- Android AAB/signing path;
- Apple/Google privacy declarations from actual binary behavior;
- age rating;
- listing assets truthful to actual game.

Do NOT submit publicly without explicit user authorization.

## Phase 8 — Fix-only loop

Create a numbered finding list sorted:
P0 startup/save/progression/privacy/security
→ P1 input/major UX/performance
→ score-impact visual/game-feel
→ P2/P3 polish.

For each finding:
`reproduce → minimal fix → targeted test → regression → device verify → close`.

No unrelated refactor unless the finding cannot be safely fixed otherwise.

## Phase 9 — Candidate freeze report

Report:
- final SHA / VERSION;
- all automated checks;
- device matrix;
- performance table;
- save/migration table;
- final visual score;
- unresolved P2/P3 list;
- SDK/permission inventory;
- Store requirement verification date;
- exact remaining release blockers, if any.

Only call the build a Release Candidate when all P0/P1 Hard Gates pass and final score target is met.
