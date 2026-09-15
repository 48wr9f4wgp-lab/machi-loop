# MACHI LOOP — Localization Gate v1

Status: Japan-first / English-ready architecture gate

## Product decision

- Launch language priority: Japanese.
- Architecture must remain English-ready.
- English store/product localization is not claimed complete until actual LQA is performed.

## RC requirements — Japanese

- No missing Japanese glyphs in all primary flows.
- Currency/numbers remain readable at target device widths.
- No critical text overlaps or truncates unexpectedly.
- Tutorial, settings, policy, service, warning, goal, tier, and save/recovery text are reviewed in context.
- Japanese subset-font generation is reproducible in CI.
- Final device screenshots are taken from the same build family that passed the release gate.

## English-ready engineering requirements

Before claiming English support:
- Stable localization keys instead of duplicated copy variants.
- No critical gameplay instruction baked into images.
- UI tolerates ~30–50% text expansion in key controls.
- Locale-aware number/currency formatting decision documented.
- Pseudo-localization pass completed.
- English linguistic QA and visual LQA completed on device.

## High-risk screens

1. FTUE instruction banner/card.
2. Demand HUD.
3. Traffic warning/recovery explanation.
4. Economy/cash state.
5. Policy selection.
6. City services selection/slot explanation.
7. City goal and reward presentation.
8. Tier-up presentation.
9. Settings.
10. Save/recovery/error communication.

## Hard blockers

- Tofu/missing glyph in primary UI.
- Important text clipped so meaning changes.
- Primary CTA label unreadable.
- Localized text overlaps critical controls.
- English-ready claim while strings remain structurally impossible to localize without code changes.

## Evidence

For each supported locale at RC:
- build/version
- device sizes tested
- screenshots of high-risk screens
- list of known truncations/intentional abbreviations
- LQA reviewer result
