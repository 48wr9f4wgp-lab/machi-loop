# MACHI LOOP — Localization Gate v1

Status: Japan-first / English-ready architecture gate

## Product decision
- Launch priority: Japanese.
- Architecture remains English-ready.
- English localization is not complete until LQA.

## RC requirements
- No missing Japanese glyphs in primary flows.
- Currency/numbers readable at target widths.
- No critical overlap/truncation.
- Tutorial/settings/policy/service/warning/goal/tier/save text reviewed in context.
- Japanese subset-font generation reproducible in CI.
- Final screenshots come from release-gated build family.

Before claiming English support: stable localization keys, no critical instructions baked into images, 30–50% text-expansion tolerance, locale-aware formatting decision, pseudo-localization, linguistic QA and device visual LQA.

## Hard blockers
Tofu/missing glyphs, meaning-changing clipping, unreadable CTA, localized text covering controls, or an English-ready claim that requires code changes to localize.
