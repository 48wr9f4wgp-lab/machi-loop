# MACHI LOOP — Accessibility Gate v1

Status: pre-RC requirements
Scope: portrait mobile Web/PWA + native iOS/Android

## Principle

Accessibility is part of product quality, not a post-release option. Critical gameplay state must remain understandable without any single sensory channel.

## Required before RC

### Color / contrast
- Critical state must never be conveyed by color alone.
- Demand, traffic, warnings, service state, affordability, and locked/unlocked state require text/icon/shape redundancy.
- Selected/unselected controls require more than hue change when practical.
- Test screenshots in grayscale and with simulated common color-vision deficiencies.

### Text
- Japanese primary gameplay text must render with no missing glyphs.
- Avoid critical body text below the practical readable size on target iPhone widths.
- Avoid important text baked into raster images.
- Long strings must wrap/truncate intentionally, never overlap neighboring controls.
- Pseudo-localization/text-expansion test is required before English-ready claim.

### Touch
- Critical actions must have forgiving touch areas, even when visual icons are smaller.
- Avoid adjacent destructive actions without spacing/confirmation semantics.
- One-handed portrait use must remain viable for the core loop.
- Safe-area insets must protect top/bottom controls.

### Motion
- Frequent core actions use short, functional feedback rather than long camera motion.
- Tier-up/major reward motion may be stronger but must not hide essential state.
- Flashing effects must be avoided or constrained.
- **Reduced Motion** is a pre-RC decision gate: either implement an option that suppresses non-essential motion or document why the final motion set is already minimal enough. This cannot remain an unreviewed TODO at RC.

### Audio
- SFX may reinforce success/error but never carry unique critical information.
- SFX OFF must preserve gameplay comprehension.
- Frequent road actions use restrained audio to avoid fatigue.
- Major reward audio must be meaningfully distinct from navigation/work feedback.

### Haptics
- Haptics OFF must preserve gameplay comprehension.
- Frequent actions use weak/short haptics.
- Major reward uses stronger but brief haptics.
- No repeated vibration spam from batched simulation events.
- Platform unsupported/no-permission path must be a safe no-op.

## Device audit scenarios

1. Fresh FTUE with sound muted.
2. Fresh FTUE with haptics disabled.
3. Dense P5_METRO city in bright ambient light.
4. Grayscale screenshot review.
5. Narrow supported iPhone width.
6. Large iPhone width.
7. Representative Android mid-range device.
8. Background/resume while an overlay is open.

## Hard blockers

- Primary CTA cannot be reliably tapped.
- Important state is only color-coded.
- Missing Japanese glyphs.
- Critical text is clipped/covered by safe area.
- Audio/haptic disabled state makes success/error ambiguous.
- Animation prevents or materially delays required input.

## Evidence to retain

For each final target device:
- model / OS
- build SHA/version
- screenshots of main HUD, settings, policy/services, warning state, dense city
- notes for sound-off and haptics-off flows
- any Reduced Motion decision/evidence
- pass/fail against this file
