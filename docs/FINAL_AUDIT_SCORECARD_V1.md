# MACHI LOOP — Final Audit Scorecard v1

Status: pre-RC gate definition
Target: public-release competitive mobile quality
Canonical dependency: GAME_DEV_MASTER_RULES Visual Quality Gate / Final Hard Gates

## Scoring

Visual/Product score target for Release Candidate: **90+ / 100**.
Hard Gates override the numerical score: one unresolved blocker means no RC regardless of average.

| Area | Weight | Evidence required | Current status before v0.22A merge |
|---|---:|---|---|
| Hierarchy | 15 | iPhone screenshots, primary CTA clarity, HUD occupancy | PENDING final device audit |
| Readability | 15 | Japanese/CJK rendering, safe area, text size, contrast | PENDING final device audit |
| Art consistency | 15 | production asset kit, road/ground/vegetation consistency | PARTIAL |
| Layout | 10 | portrait 430×932 + representative iPhone sizes | PENDING final device audit |
| Typography | 10 | Japanese subset font + hierarchy + truncation | PARTIAL |
| Iconography | 10 | consistent semantic icons and states | PENDING polish audit |
| Depth / lighting | 10 | city readability at P1/P3/P5 | PARTIAL |
| Motion / VFX | 10 | operation, reward, tier-up feedback | PARTIAL; v0.22A pending remote integration |
| Reward satisfaction | 5 | goal/tier-up feedback hierarchy | PARTIAL; v0.22A pending device listening |

## Hard Gates

Every item must be PASS before Release Candidate.

### Stability
- [ ] No reproducible startup crash.
- [ ] No normal-play progression lock.
- [ ] No normal-play input lock.
- [ ] No PWA/native save corruption under normal lifecycle use.
- [ ] Old supported save schema migration verified.
- [ ] Corrupted primary save recovery verified.

### Core loop
- [ ] Main road commit is immediately understandable.
- [ ] Autonomous growth visibly follows the road decision.
- [ ] Demand pressure is understandable without hidden-formula knowledge.
- [ ] Traffic can be worsened and recovered through player decisions.
- [ ] Economy can become pressured without creating an unrecoverable soft-lock.
- [ ] Services/policies create materially different choices.
- [ ] City tiers add capability and pressure, not only bigger numbers.

### FTUE
- [ ] First input has one obvious action.
- [ ] First road → growth → reward chain completes without reading a manual.
- [ ] First management problem is introduced after success, not before it.
- [ ] FTUE resumes after interruption.
- [ ] Existing developed saves never get forced back into FTUE.

### UI / Accessibility
- [ ] Critical CTA touch targets are comfortable on iPhone.
- [ ] Critical information is never encoded by color alone.
- [ ] Important feedback remains understandable with SFX off.
- [ ] Important feedback remains understandable with haptics off.
- [ ] No primary HUD content is hidden by safe-area/notch/home indicator.
- [ ] Japanese text has no tofu/missing glyphs.
- [ ] No unreadable text at target device widths.
- [ ] Motion does not obscure gameplay; Reduced Motion decision is explicitly audited before RC.

### Audio / Haptics
- [ ] Road commit feedback is short and low-intensity.
- [ ] Goal completion is clearly higher-value than road commit.
- [ ] City tier-up is clearly the strongest normal success event.
- [ ] Repeated frequent actions do not create annoying haptic spam.
- [ ] SFX/haptics settings persist.
- [ ] Production audio is licensed/original and provenance is recorded.

### Performance
- [ ] Named P1_FTUE baseline measured on real iPhone.
- [ ] Named P3_MID baseline measured on real iPhone.
- [ ] Named P5_METRO stress baseline measured on real iPhone.
- [ ] No sustained <30 FPS normal-play segment for >=5 s on minimum supported device.
- [ ] No >=100 ms recurring critical road-input stall.
- [ ] 10–20 minute device run does not show unacceptable thermal collapse.
- [ ] Save/reload does not produce visible gameplay freeze or data loss.

### Privacy / Security
- [ ] No secrets/signing credentials are tracked in Git.
- [ ] No direct PII is sent by analytics.
- [ ] No full save payload or free-form user text is sent by analytics.
- [ ] Analytics failures cannot block gameplay/save.
- [ ] Third-party SDK inventory is documented before any provider is enabled.
- [ ] Store privacy disclosures are checked against the actual final binary/SDK list.

### Release / Store
- [ ] Android target API meets current Play requirement at submission time.
- [ ] Android signed release artifact builds and installs.
- [ ] iOS build is produced on macOS/Xcode using current App Store SDK minimum.
- [ ] iOS signed build installs on device.
- [ ] App icon / launch / screenshots / description reflect actual gameplay.
- [ ] Current age-rating questions completed.
- [ ] Premium price is decided only after current competitor/store research.
- [ ] Store submission/publishing has explicit user approval.

## Final Audit evidence pack

For each failure or score deduction record:
- Current evidence
- Benchmark gap
- Specific change
- Target file/system
- Expected benefit
- Cost
- Risk
- Priority
- Verification method

## RC decision

- **GO**: all Hard Gates PASS and score >=90.
- **POLISH**: no critical stability/save/security blocker, score 80–89 or minor gates pending.
- **REDESIGN**: score 70–79 or a core-loop/FTUE/interaction gate fails.
- **BLOCK**: any crash/progression/save/privacy/store critical gate fails, regardless of score.
